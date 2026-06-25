#!/usr/bin/env bash
#
# bootstrap_brain.sh — idempotently scaffold the "brain" + "raw sources" layers.
#
# This is part of the personal chief-of-staff assistant (Karpathy LLM-Wiki
# pattern). It creates the two on-device data layers that live OUTSIDE this repo:
#
#   ~/brain/    (Layer 2) LLM-owned synthesis: goals, context, daily, briefs,
#               config, signals, plus index.md / log.md / CLAUDE.md.
#   ~/sources/  (Layer 1) immutable raw pulled from connectors (Slack/Calendar).
#
# It seeds the brain from this repo's templates/ and config/ WITHOUT clobbering
# anything that already exists, so it is safe to re-run.
#
# Usage:
#   ./scripts/bootstrap_brain.sh
#
# Env overrides:
#   BRAIN_DIR    (default: ~/brain)
#   SOURCES_DIR  (default: ~/sources)
#
# This script runs on the user's Mac (zsh/bash). It performs NO network calls,
# NO git, and writes nothing inside this repo.

set -euo pipefail

# --------------------------------------------------------------------------- #
# Locate the repo root relative to this script, so templates resolve no matter
# where the script is invoked from.
# --------------------------------------------------------------------------- #
SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
# Resolve symlinks to the real script path.
while [ -h "$SCRIPT_SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
# scripts/ lives directly under the repo root.
REPO_ROOT="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

TEMPLATES_DIR="$REPO_ROOT/templates"
CONFIG_DIR="$REPO_ROOT/config"

# --------------------------------------------------------------------------- #
# Resolve target locations (env-overridable).
# --------------------------------------------------------------------------- #
BRAIN_DIR="${BRAIN_DIR:-$HOME/brain}"
SOURCES_DIR="${SOURCES_DIR:-$HOME/sources}"

# --------------------------------------------------------------------------- #
# Pretty output helpers + counters for the final summary.
# --------------------------------------------------------------------------- #
CREATED=()
SKIPPED=()
WARNINGS=()

log()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; WARNINGS+=("$*"); }

# --------------------------------------------------------------------------- #
# mkdir_safe DIR — create a directory (and parents) idempotently, recording
# whether it was newly created.
# --------------------------------------------------------------------------- #
mkdir_safe() {
  local dir="$1"
  if [ -d "$dir" ]; then
    SKIPPED+=("dir  $dir")
  else
    mkdir -p "$dir"
    CREATED+=("dir  $dir")
  fi
}

# --------------------------------------------------------------------------- #
# copy_template SRC DST — copy a repo template into the brain ONLY if the
# destination does not already exist. Never overwrites. Warns (does not crash)
# if the source template is missing, since templates may be authored separately.
# --------------------------------------------------------------------------- #
copy_template() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    SKIPPED+=("file $dst (already exists)")
    return 0
  fi
  if [ ! -f "$src" ]; then
    warn "template missing: $src — skipped (expected target: $dst)"
    return 0
  fi
  # Ensure the parent dir exists before copying.
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  CREATED+=("file $dst")
}

# --------------------------------------------------------------------------- #
# seed_signal DST HEADER_TEMPLATE — ensure an append-only signal file exists.
# If absent, create it; if a header template is available, seed the file with
# it, otherwise create an empty file. Never overwrites an existing file.
# --------------------------------------------------------------------------- #
seed_signal() {
  local dst="$1" header_src="$2"
  if [ -e "$dst" ]; then
    SKIPPED+=("file $dst (already exists)")
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -f "$header_src" ]; then
    cp "$header_src" "$dst"
    CREATED+=("file $dst (seeded from $(basename "$header_src"))")
  else
    : > "$dst"   # create empty file
    CREATED+=("file $dst (empty)")
  fi
}

# --------------------------------------------------------------------------- #
# Sanity check: warn loudly if the templates dir is missing entirely, but keep
# going — directory creation is still useful and copies will warn individually.
# --------------------------------------------------------------------------- #
log "Chief-of-Staff brain bootstrap"
log "  repo root   : $REPO_ROOT"
log "  brain dir   : $BRAIN_DIR"
log "  sources dir : $SOURCES_DIR"
log ""

if [ ! -d "$TEMPLATES_DIR" ]; then
  warn "templates directory not found: $TEMPLATES_DIR — files will be skipped."
fi
if [ ! -d "$CONFIG_DIR" ]; then
  warn "config directory not found: $CONFIG_DIR — sources.yml will be skipped."
fi

# --------------------------------------------------------------------------- #
# 1. Create the brain + raw directory skeletons.
# --------------------------------------------------------------------------- #
log "Creating directory skeletons..."
mkdir_safe "$BRAIN_DIR"
mkdir_safe "$BRAIN_DIR/goals"
mkdir_safe "$BRAIN_DIR/context"
mkdir_safe "$BRAIN_DIR/context/projects"
mkdir_safe "$BRAIN_DIR/context/people"
mkdir_safe "$BRAIN_DIR/context/topics"
mkdir_safe "$BRAIN_DIR/daily"
mkdir_safe "$BRAIN_DIR/briefs"
mkdir_safe "$BRAIN_DIR/config"
mkdir_safe "$BRAIN_DIR/signals"

# Raw layer (immutable sources). V1 = Slack + Google Calendar.
mkdir_safe "$SOURCES_DIR"
mkdir_safe "$SOURCES_DIR/slack"
mkdir_safe "$SOURCES_DIR/calendar"

# --------------------------------------------------------------------------- #
# 2. Seed brain files from repo templates (never overwriting).
#    Mapping is defined by the build plan / shared conventions.
# --------------------------------------------------------------------------- #
log "Seeding brain files from templates (existing files left untouched)..."
copy_template "$TEMPLATES_DIR/index.md"          "$BRAIN_DIR/index.md"
copy_template "$TEMPLATES_DIR/log.md"            "$BRAIN_DIR/log.md"
copy_template "$TEMPLATES_DIR/brain.CLAUDE.md"   "$BRAIN_DIR/CLAUDE.md"
copy_template "$TEMPLATES_DIR/goal.company.md"   "$BRAIN_DIR/goals/company.md"
copy_template "$TEMPLATES_DIR/goal.team.md"      "$BRAIN_DIR/goals/team.md"
copy_template "$TEMPLATES_DIR/goal.personal.md"  "$BRAIN_DIR/goals/personal.md"
copy_template "$TEMPLATES_DIR/weightings.md"     "$BRAIN_DIR/goals/weightings.md"

# Populated config lives in the brain (personal data, never pushed). The repo
# ships only the example.
copy_template "$CONFIG_DIR/sources.example.yml"  "$BRAIN_DIR/config/sources.yml"

# --------------------------------------------------------------------------- #
# 3. Seed append-only signal files (human-reviewed queues).
# --------------------------------------------------------------------------- #
log "Seeding signal queues..."
seed_signal "$BRAIN_DIR/signals/recalibration.md" "$TEMPLATES_DIR/recalibration.entry.md"
seed_signal "$BRAIN_DIR/signals/new-channels.md"  "$TEMPLATES_DIR/new-channels.entry.md"

# --------------------------------------------------------------------------- #
# 4. Summary + next steps.
# --------------------------------------------------------------------------- #
log ""
log "==================== SUMMARY ===================="
if [ "${#CREATED[@]}" -gt 0 ]; then
  log "Created (${#CREATED[@]}):"
  for item in "${CREATED[@]}"; do info "+ $item"; done
else
  log "Created: nothing new (everything already in place)."
fi
log ""
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  log "Skipped / already present (${#SKIPPED[@]}):"
  for item in "${SKIPPED[@]}"; do info "= $item"; done
fi
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  log ""
  log "Warnings (${#WARNINGS[@]}):"
  for item in "${WARNINGS[@]}"; do info "! $item"; done
fi
log "================================================="
log ""
log "Next steps:"
log "  1. Edit your goals in $BRAIN_DIR/goals/ — run the 'onboard' skill in"
log "     Claude Code to draft them interactively (or fill the <FILL IN> markers"
log "     by hand). goals/ is HUMAN-OWNED; ingestion never writes there."
log "  2. Populate $BRAIN_DIR/config/sources.yml with the Slack channels / DMs"
log "     and calendars you want pulled (see comments in that file)."
log "  3. Index the brain + raw with QMD:  ./scripts/qmd_setup.sh"
log ""
log "Note: $SOURCES_DIR is the IMMUTABLE raw layer — connectors write here,"
log "nothing edits it. $BRAIN_DIR is LLM-owned synthesis."
