#!/usr/bin/env bash
#
# qmd_setup.sh — install, configure, and run QMD over the assistant's data.
#
# QMD (github.com/tobi/qmd) is the deterministic retrieval layer for the
# chief-of-staff assistant. It indexes TWO collections:
#
#   "brain"   -> $BRAIN_DIR   (PRIMARY)   the LLM-owned synthesis (markdown)
#   "sources" -> $SOURCES_DIR (SECONDARY) the immutable raw (markdown + json)
#
# Per the build plan, the brain (synthesis) is the PRIMARY collection; the raw
# layer is SECONDARY. Briefs read the curated index/context first and fall back
# to QMD search; QMD does not replace the wiki, it backstops it.
#
# Everything is fully local: QMD's default embedder is EmbeddingGemma, on-device.
#
# Usage:
#   ./scripts/qmd_setup.sh <command>
#
# Commands:
#   install   Install the qmd CLI if it is not already on PATH.
#   init      Register the two collections (idempotent) and build embeddings.
#   reindex   Re-embed after the brain/raw changed.
#   start     Start the QMD MCP server as an HTTP daemon (localhost:8181).
#   stop      Stop the MCP daemon.
#   status    Report daemon health + index status.
#   all       install -> init -> start  (also the default if no command given).
#
# Env overrides:
#   COS_ROOT     (default: ~/chief-of-staff)   parent dir for both layers
#   BRAIN_DIR    (default: $COS_ROOT/brain)
#   SOURCES_DIR  (default: $COS_ROOT/sources)
#   QMD_HTTP_PORT (default: 8181)   # the MCP HTTP daemon port
#
# This script runs on the user's Mac (zsh/bash).
#
# !!! VERIFY ON FIRST RUN !!!
# qmd is young and its subcommand/flag names vary by version. Each qmd
# invocation below is annotated where the exact syntax is uncertain. Run
# `qmd --help` and `qmd <subcommand> --help` to confirm before trusting a run.

set -euo pipefail

# --------------------------------------------------------------------------- #
# Config.
# --------------------------------------------------------------------------- #
COS_ROOT="${COS_ROOT:-$HOME/chief-of-staff}"
BRAIN_DIR="${BRAIN_DIR:-$COS_ROOT/brain}"
SOURCES_DIR="${SOURCES_DIR:-$COS_ROOT/sources}"
QMD_HTTP_PORT="${QMD_HTTP_PORT:-8181}"
QMD_HTTP_HOST="localhost"

# Collection names (referenced in MCP queries + the brief skill).
BRAIN_COLLECTION="brain"
SOURCES_COLLECTION="sources"

log()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Does a command exist on PATH?
have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------------------- #
# install — ensure the qmd CLI is available.
#
# Per upstream docs, qmd installs as a global npm/bun package:
#   npm install -g @tobilu/qmd
#   bun install -g @tobilu/qmd
# (npx/bunx also work but a persistent daemon wants a real install.)
# VERIFY: confirm the published package name (@tobilu/qmd) on first run.
# --------------------------------------------------------------------------- #
cmd_install() {
  if have qmd; then
    log "qmd already installed: $(command -v qmd)"
    qmd --version 2>/dev/null || true
    return 0
  fi

  log "qmd not found on PATH — attempting install..."
  if have npm; then
    log "  Running: npm install -g @tobilu/qmd"
    npm install -g @tobilu/qmd
  elif have bun; then
    log "  Running: bun install -g @tobilu/qmd"
    bun install -g @tobilu/qmd
  else
    die "Neither npm nor bun found. Install Node.js (npm) or Bun, then re-run:
       npm install -g @tobilu/qmd
   or  bun install -g @tobilu/qmd"
  fi

  if have qmd; then
    log "qmd installed: $(command -v qmd)"
  else
    die "qmd still not on PATH after install. Check your global bin dir is on PATH
       (e.g. \$(npm bin -g) or ~/.bun/bin)."
  fi
}

# --------------------------------------------------------------------------- #
# Require qmd present for commands that need it.
# --------------------------------------------------------------------------- #
require_qmd() {
  have qmd || die "qmd not installed. Run: $0 install"
}

# --------------------------------------------------------------------------- #
# add_collection NAME PATH [GLOBS...] — register a QMD collection idempotently.
#
# QMD stores collections in ~/.config/qmd/index.yml. We guard against
# double-adding by grepping that config for the collection name first; if the
# CLI errors because the collection already exists we treat that as success too.
#
# VERIFY: exact flag for the path/name/glob. Best-known form:
#   qmd collection add <path> --name <name> [--glob '<pattern>' ...]
# Some versions may use `qmd add`, positional name, or a single comma-separated
# --globs. Adjust here if `qmd collection --help` differs.
# --------------------------------------------------------------------------- #
add_collection() {
  local name="$1"; shift
  local path="$1"; shift
  local globs=("$@")

  if [ ! -d "$path" ]; then
    warn "collection path does not exist: $path (run bootstrap_brain.sh first?)"
  fi

  # Idempotency guard: skip if already present in the qmd config.
  local cfg="$HOME/.config/qmd/index.yml"
  if [ -f "$cfg" ] && grep -q "$name" "$cfg" 2>/dev/null; then
    log "  collection '$name' already registered (found in $cfg) — skipping add."
    return 0
  fi

  # Build the glob args. If none given, qmd uses its defaults.
  local glob_args=()
  local g
  for g in "${globs[@]:-}"; do
    [ -n "$g" ] && glob_args+=(--glob "$g")
  done

  log "  Adding collection '$name' -> $path ${glob_args[*]:-}"
  # `|| true` so an "already exists" error from the CLI doesn't abort the run;
  # the config-grep above is the primary guard.
  if ! qmd collection add "$path" --name "$name" "${glob_args[@]}"; then
    warn "qmd collection add for '$name' returned non-zero — it may already
       exist, or the subcommand syntax differs in your qmd version. VERIFY with
       'qmd collection --help'."
  fi
}

# --------------------------------------------------------------------------- #
# init — register both collections and build embeddings.
# --------------------------------------------------------------------------- #
cmd_init() {
  require_qmd
  log "Registering QMD collections (brain = PRIMARY, sources = SECONDARY)..."

  # PRIMARY: the brain (synthesis). Markdown only.
  add_collection "$BRAIN_COLLECTION" "$BRAIN_DIR" '**/*.md'

  # SECONDARY: immutable raw. Slack lands as .json (+ rendered .md); calendar
  # as .md. Index both extensions.
  add_collection "$SOURCES_COLLECTION" "$SOURCES_DIR" '**/*.md' '**/*.json'

  log "Building embeddings (local EmbeddingGemma)..."
  # VERIFY: `qmd embed` is the documented embed command; some versions may
  # scan+embed in one step or need an explicit `qmd index`/`qmd scan` first.
  qmd embed

  log "init complete. Try:  qmd query 'what did I decide about X'"
}

# --------------------------------------------------------------------------- #
# reindex — re-embed after the brain or raw changed.
# --------------------------------------------------------------------------- #
cmd_reindex() {
  require_qmd
  log "Re-embedding collections after changes..."
  # NOTE: depending on qmd version, `qmd embed` may only embed NEW/CHANGED docs
  # automatically, or may require an explicit rescan of collection paths first.
  # VERIFY whether a `qmd scan`/`qmd index` step is needed; if so, add it here.
  qmd embed
  log "reindex complete."
}

# --------------------------------------------------------------------------- #
# start — run the MCP server as an HTTP daemon on localhost.
#
# VERIFY: documented form is `qmd mcp --http --daemon`, listening on
# localhost:8181 with /mcp and /health endpoints. The MCP tools are reported as
# query / get / multi_get / status — CONFIRM exact names against the running
# server (e.g. via /health or the MCP client) before wiring skills to them.
# --------------------------------------------------------------------------- #
cmd_start() {
  require_qmd
  if is_daemon_up; then
    log "MCP daemon already running at http://$QMD_HTTP_HOST:$QMD_HTTP_PORT"
    return 0
  fi
  log "Starting QMD MCP HTTP daemon on http://$QMD_HTTP_HOST:$QMD_HTTP_PORT ..."
  # If your qmd build takes an explicit --port, append it here; default is 8181.
  qmd mcp --http --daemon
  # Give it a moment to bind, then confirm.
  sleep 1
  if is_daemon_up; then
    log "MCP daemon is up. Endpoints: /mcp (MCP), /health (health check)."
  else
    warn "Daemon did not report healthy yet. Check 'qmd mcp --help' for the
       correct daemon flags/port, then re-run '$0 status'."
  fi
}

# --------------------------------------------------------------------------- #
# stop — stop the MCP daemon.
# --------------------------------------------------------------------------- #
cmd_stop() {
  require_qmd
  log "Stopping QMD MCP daemon..."
  # VERIFY: `qmd mcp stop` is the documented stop command.
  qmd mcp stop || warn "'qmd mcp stop' returned non-zero (daemon may already be
       stopped, or the stop subcommand differs in your version)."
}

# --------------------------------------------------------------------------- #
# is_daemon_up — true if the health endpoint responds.
# --------------------------------------------------------------------------- #
is_daemon_up() {
  if have curl; then
    curl -fsS "http://$QMD_HTTP_HOST:$QMD_HTTP_PORT/health" >/dev/null 2>&1
  else
    return 1
  fi
}

# --------------------------------------------------------------------------- #
# status — report daemon health + index status.
# --------------------------------------------------------------------------- #
cmd_status() {
  require_qmd
  log "QMD status"
  log "  brain   (PRIMARY)   : $BRAIN_DIR"
  log "  sources (SECONDARY) : $SOURCES_DIR"
  log "  config              : ${HOME}/.config/qmd/index.yml"
  log ""

  log "MCP daemon (http://$QMD_HTTP_HOST:$QMD_HTTP_PORT):"
  if have curl; then
    if curl -fsS "http://$QMD_HTTP_HOST:$QMD_HTTP_PORT/health" 2>/dev/null; then
      printf '\n'
      log "  -> healthy"
    else
      log "  -> not responding (run '$0 start')"
    fi
  else
    warn "curl not found; cannot probe /health. Install curl or use the qmd CLI."
  fi

  log ""
  log "Index status (qmd):"
  # VERIFY: `qmd status` exact name/output; may be `qmd info`/`qmd collection
  # list` depending on version.
  qmd status 2>/dev/null || warn "'qmd status' unavailable — try 'qmd --help'."
}

# --------------------------------------------------------------------------- #
# usage.
# --------------------------------------------------------------------------- #
usage() {
  cat <<EOF
qmd_setup.sh — install/configure/run QMD for the chief-of-staff assistant.

Usage: $0 <command>

Commands:
  install   Install the qmd CLI (npm, falling back to bun).
  init      Register collections (brain=PRIMARY, sources=SECONDARY) + embed.
  reindex   Re-embed after brain/raw changes.
  start     Start the MCP HTTP daemon on localhost:$QMD_HTTP_PORT.
  stop      Stop the MCP daemon.
  status    Show daemon health + index status.
  all       install -> init -> start  (default if no command is given).

Env: BRAIN_DIR (=$BRAIN_DIR), SOURCES_DIR (=$SOURCES_DIR),
     QMD_HTTP_PORT (=$QMD_HTTP_PORT)

After 'start', wire the MCP server into Claude Code / Claude Desktop so the
assistant can call QMD's tools (query / get / multi_get / status — VERIFY
names). See docs/SETUP.md for the exact MCP client configuration.
EOF
}

# --------------------------------------------------------------------------- #
# Dispatch.
# --------------------------------------------------------------------------- #
main() {
  local cmd="${1:-all}"
  case "$cmd" in
    install) cmd_install ;;
    init)    cmd_init ;;
    reindex) cmd_reindex ;;
    start)   cmd_start ;;
    stop)    cmd_stop ;;
    status)  cmd_status ;;
    all)
      cmd_install
      cmd_init
      cmd_start
      log ""
      log "Done. Next: wire the MCP daemon into Claude Code/Desktop — see"
      log "docs/SETUP.md. The brain is indexed as PRIMARY, raw as SECONDARY."
      ;;
    -h|--help|help) usage ;;
    *)
      warn "unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
