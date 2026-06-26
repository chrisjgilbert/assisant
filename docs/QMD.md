# QMD — how it works (illustrative reference)

> **What this is.** A simplified, annotated **mockup** of how QMD
> (github.com/tobi/qmd) indexes content and answers queries — written to explain
> the key concepts that matter for this project. It is **reconstructed from QMD's
> dependency stack and public API surface, not copied from upstream source.** The
> code below is illustrative pseudo-TypeScript: correct in shape, not verbatim.
> For the real implementation read the repo (`src/index.ts`, `src/collections.ts`,
> `src/store.ts`, `src/db.ts`, `src/mcp/server.ts`). Command/flag names are
> verified against the qmd README but can vary by version — confirm with
> `qmd --help` on first run.

## Why this doc exists

QMD is the retrieval substrate under the brain (see [ARCHITECTURE.md](ARCHITECTURE.md)
§4). It is *plumbing*, not the product — the compounding synthesis is the product
and navigation (`index.md` first) is the primary retrieval path; QMD is the
search fallback and the recall safety-net at scale. This doc explains what that
fallback is actually doing.

## Verified component stack (from `package.json`)

These are real and load-bearing:

| Dependency | Role |
|---|---|
| `better-sqlite3` | the entire store (single local SQLite file) |
| `sqlite-vec` | vector index + KNN search as a SQLite extension (`vec0`) |
| SQLite `FTS5` (built in) | keyword/BM25 inverted index |
| `node-llama-cpp` | local embeddings **and** local LLM (query expansion + rerank) |
| `web-tree-sitter` + grammars | AST-aware chunking for code files |
| `fast-glob` / `picomatch` | collection file matching (`--mask` globs) |
| `yaml` + `zod` | parse/validate `~/.config/qmd/index.yml` |
| `@modelcontextprotocol/sdk` | the MCP server Claude talks to |

Two indexes (keyword + vector) live over the same chunks in one SQLite DB.
Everything runs on-device.

---

## 0. The data model — SQLite is the whole store

```ts
import Database from "better-sqlite3";
import * as sqliteVec from "sqlite-vec";

const db = new Database("~/.config/qmd/qmd.db");
sqliteVec.load(db);                 // registers vec0 virtual tables
db.pragma("journal_mode = WAL");

db.exec(`
  -- one row per source file
  CREATE TABLE IF NOT EXISTS documents (
    id         INTEGER PRIMARY KEY,
    collection TEXT,                -- "brain" | "sources"
    path       TEXT UNIQUE,         -- ~/chief-of-staff/brain/context/slack.md
    title      TEXT,
    hash       TEXT                 -- content hash → skip re-index if unchanged
  );

  -- documents are split into ~900-token chunks; search happens at chunk level
  CREATE TABLE IF NOT EXISTS chunks (
    id     INTEGER PRIMARY KEY,
    doc_id INTEGER REFERENCES documents(id),
    ord    INTEGER,                 -- chunk position within the doc
    text   TEXT
  );

  -- (1) KEYWORD INDEX: FTS5 inverted index over chunk text (BM25 built in)
  CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts
    USING fts5(text, content='chunks', content_rowid='id');

  -- (2) VECTOR INDEX: sqlite-vec stores one embedding per chunk
  CREATE VIRTUAL TABLE IF NOT EXISTS chunks_vec
    USING vec0(chunk_id INTEGER PRIMARY KEY, embedding FLOAT[768]);
`);
```

Two indexes, same chunks: **FTS5** for keywords, **vec0** for meaning.

## 1. Indexing (`qmd update`) — scan, chunk, populate FTS

```ts
import fg from "fast-glob";

function updateCollection(name: string, root: string, mask = "**/*.md") {
  for (const path of fg.sync(mask, { cwd: root, absolute: true })) {
    const raw  = fs.readFileSync(path, "utf8");
    const hash = sha256(raw);
    if (unchanged(path, hash)) continue;          // content-hash skip

    const docId = upsertDocument(name, path, titleOf(raw), hash);
    deleteOldChunks(docId);

    for (const [ord, text] of chunk(raw).entries()) {   // ~900-token passages
      const chunkId = insertChunk(docId, ord, text);
      db.prepare(`INSERT INTO chunks_fts(rowid, text) VALUES (?, ?)`)
        .run(chunkId, text);                      // → keyword index
    }
  }
}
```

The chunker is quietly important: split on natural boundaries (headings,
paragraphs) targeting ~900 tokens, so each chunk is a coherent passage. Code
files use tree-sitter AST chunking instead; our markdown brain uses the prose
chunker.

## 2. Embedding (`qmd embed`) — fill the vector index locally

```ts
import { getLlama } from "node-llama-cpp";

const llama = await getLlama();
const model = await llama.loadModel({ modelPath: "embeddinggemma-Q4.gguf" });
const ctx   = await model.createEmbeddingContext();

async function embedPending() {
  for (const { id, text } of chunksWithoutEmbedding()) {
    const { vector } = await ctx.getEmbedding(text);    // on-device, no network
    db.prepare(`INSERT INTO chunks_vec(chunk_id, embedding) VALUES (?, ?)`)
      .run(id, new Float32Array(vector));
  }
}
```

Everything runs through llama.cpp on your machine — the "fully local" guarantee.

## 3. The two primitive searches

```ts
// (1) BM25 keyword search — FTS5 does the ranking
function searchFTS(query: string, limit = 50): Hit[] {
  return db.prepare(`
    SELECT c.id, c.doc_id, bm25(chunks_fts) AS score
    FROM chunks_fts JOIN chunks c ON c.id = chunks_fts.rowid
    WHERE chunks_fts MATCH ?
    ORDER BY score LIMIT ?`           // bm25() ascending = better
  ).all(query, limit);
}

// (2) Vector search — embed the query, ask sqlite-vec for nearest neighbours
async function searchVec(query: string, limit = 50): Promise<Hit[]> {
  const { vector } = await ctx.getEmbedding(query);
  return db.prepare(`
    SELECT chunk_id AS id, distance AS score
    FROM chunks_vec
    WHERE embedding MATCH ? ORDER BY distance LIMIT ?`   // cosine/L2 KNN
  ).all(new Float32Array(vector), limit);
}
```

## 4. Fusion — Reciprocal Rank Fusion (the "hybrid" glue)

```ts
// Combine two ranked lists by RANK, not raw score (scales are incomparable).
function rrf(lists: Hit[][], k = 60): Scored[] {
  const acc = new Map<number, number>();
  for (const list of lists)
    list.forEach((hit, rank) =>
      acc.set(hit.id, (acc.get(hit.id) ?? 0) + 1 / (k + rank)));   // 1/(k+rank)
  return [...acc].map(([id, score]) => ({ id, score }))
                 .sort((a, b) => b.score - a.score);
}
```

A chunk ranked high in *either* list rises; ranked high in *both* rises most.
`k≈60` damps top-rank dominance.

## 5. The hybrid orchestrator (`qmd query`)

```ts
async function query(q: string, topN = 10): Promise<Result[]> {
  // a) expand: LLM rewrites the query into a few variations to widen recall
  const variants = [q, ...(await expandQuery(q))];

  // b) run both searches over all variants, in parallel
  const lists = await Promise.all(
    variants.flatMap(v => [searchFTS(v), searchVec(v)])
  );

  // c) fuse the ranked lists
  const fused = rrf(lists).slice(0, 50);

  // d) rerank survivors with a cross-encoder (local Qwen3-reranker) — reads
  //    (query, chunk) together and scores true relevance
  const reranked = await rerank(q, fused.map(loadChunkText));

  // e) drop the long tail at a natural score gap; return top N with provenance
  const cut = findBestCutoff(reranked);
  return reranked.slice(0, Math.min(cut, topN)).map(withDocPathAndSnippet);
}
```

The funnel: **expand → (BM25 ∥ vector) → RRF → rerank → cutoff**. Recall is
gathered cheaply and broadly, then precision is bought with the expensive
reranker on a small candidate set.

(`qmd search` = BM25 only; `qmd vsearch` = vector only; `qmd query` = the full
hybrid above.)

## 6. Exposing it over MCP (what Claude actually calls)

```ts
server.tool("query", { q: z.string(), n: z.number().optional() },
  async ({ q, n }) => ({ content: json(await query(q, n)) }));

server.tool("get",       { path: z.string() }, ...);   // fetch one full doc
server.tool("multi_get", { paths: z.array(z.string()) }, ...);
server.tool("status",    {}, ...);                     // collections / counts
```

`qmd mcp --http --daemon` serves these on `localhost:8181`; the `daily-brief`
and `query` skills call `query`/`get` as the search fallback over the brain.

---

## The whole loop in one line

files → chunk → (FTS index + local embeddings in SQLite) → query expands →
keyword & vector search in parallel → RRF-fused → locally reranked → top-N with
citations, served to Claude over MCP.

## How this maps onto our project

- QMD indexes **two collections**: `brain` (PRIMARY) and `sources` (SECONDARY) —
  configured in `~/.config/qmd/index.yml` and built by `scripts/qmd_setup.sh`.
- `qmd_setup.sh init` runs `qmd update` (steps 1) then `qmd embed` (step 2);
  `reindex` re-runs both after each `ingest`.
- The skills navigate `index.md` + context pages **first**; they fall back to the
  `query` MCP tool (steps 3–6) for recall and raw verification.
- Remember the naming clash: QMD "indexing" is mechanical (this doc); the
  project's `ingest` skill is LLM synthesis. Different layers.
