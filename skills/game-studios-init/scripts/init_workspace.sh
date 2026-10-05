#!/usr/bin/env bash
# Game Studios workspace scaffolder (POSIX sh + awk; bash shebang is safe —
# the hooks already require bash, and this avoids the Windows python-shim
# roulette for the one script that must run first on a fresh machine).
#
# Copies per-project seeds from the game-studios plugin into a game workspace:
# directory skeleton, technical preferences (hooks marker file), architecture
# registries, host settings (statusline + permissions), path-scoped rules,
# AGENTS.md (collaboration protocol + anti-compression anchor), and a managed
# .gitignore block.
#
# Idempotent: existing files are NEVER overwritten; only the managed anchor
# block in AGENTS.md and the managed .gitignore block are replaced in place.
#
# Usage:
#   init_workspace.sh [WORKSPACE_DIR] [--check] [--dry-run]
#
# Exit codes: 0 = ok (or nothing to do), 1 = error.
# Anchor-block surgery uses awk only — no sed multiline (broken on Git Bash).

set -u

PLUGIN_MARKER=".claude-plugin/plugin.json"
GITIGNORE_BEGIN="# === Game Studios plugin (managed) ==="
ANCHOR_BEGIN='<!-- ZCGS:BEGIN -->'
ANCHOR_END='<!-- ZCGS:END -->'

MODE="APPLY"
DRY=0
WS=""

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \?//'
}

die() {
  echo "error: $*" >&2
  exit 1
}

say() {
  echo "$*"
}

# ── args ──────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="CHECK"; DRY=1 ;;
    --dry-run) MODE="DRY-RUN"; DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) if [ -z "$WS" ]; then WS="$1"; else die "unexpected argument: $1"; fi ;;
  esac
  shift
done
WS="${WS:-$PWD}"

# ── resolve plugin root (scripts/ -> skill/ -> skills/ -> plugin root) ───
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ASSETS="$SCRIPT_DIR/../assets"

[ -f "$PLUGIN_ROOT/$PLUGIN_MARKER" ] || die "plugin marker not found at $PLUGIN_ROOT/$PLUGIN_MARKER"

mkdir -p "$WS" || die "cannot create workspace: $WS"
WS="$(cd "$WS" && pwd)"

case "$WS" in
  "$PLUGIN_ROOT"|"$PLUGIN_ROOT"/*) die "refusing to scaffold inside the plugin repo itself" ;;
esac

# ── helpers ───────────────────────────────────────────────────────────────
# Copy a file as LF text (strip CR so autocrlf checkouts cannot poison
# bash scripts / JSON in the target workspace).
# NOTE: sh has no locals — every function uses its own cf_/en_/gi_ prefixed
# names so nested calls cannot clobber each other's state.
copy_file() { # $1 = absolute source, $2 = workspace-relative destination
  cf_src="$1"
  cf_dst_rel="$2"
  cf_dst="$WS/$cf_dst_rel"
  if [ -e "$cf_dst" ]; then
    say "[skipped] $cf_dst_rel (already exists)"
    return
  fi
  if [ $DRY -eq 0 ]; then
    mkdir -p "$(dirname "$cf_dst")"
    tr -d '\r' < "$cf_src" > "$cf_dst"
  fi
  say "[created] $cf_dst_rel"
}

copy_tree() { # $1 = absolute source dir, $2 = workspace-relative base
  ct_src="$1"
  ct_base="$2"
  # Subshell keeps the cd confined; "./"-relative find output avoids any
  # prefix comparison (MSYS pwd may return Windows form, find POSIX form).
  ( cd "$ct_src" && find . -type f -print0 ) | while IFS= read -r -d '' f; do
    rel="${f#./}"
    copy_file "$ct_src/$rel" "$ct_base/$rel"
  done
}

ensure_dirs() {
  for d in src assets design design/gdd docs docs/architecture docs/registry \
           tests tools prototypes \
           production/session-state production/session-logs \
           production/sprints production/milestones; do
    if [ -d "$WS/$d" ]; then
      say "[skipped] $d/ (already exists)"
    else
      [ $DRY -eq 0 ] && mkdir -p "$WS/$d"
      say "[created] $d/"
    fi
  done
}

# Print the file with every anchor block removed (awk only; index() avoids regex).
strip_anchor() {
  awk -v b="$ANCHOR_BEGIN" -v e="$ANCHOR_END" '
    index($0, b) { inblk = 1; next }
    inblk && index($0, e) { inblk = 0; next }
    !inblk { print }
  ' "$1"
}

print_anchor() {
  cat <<ANCHOREOF
$ANCHOR_BEGIN
## ZCGS Orchestrator — Anti-Compression Anchor

> Managed by the game-studios plugin's init script. Do not edit this block manually — rerun the init skill to refresh.
> This block is STATIC — it holds instructions and pointers, never live state values.

### State Pointer (live state lives here — this block never holds stale values)

- Run state (machine truth): \`production/auto-game-in-sleep/state.json\`
  - If it does not exist, the run has not started — create it per the skill's heartbeat discipline (see below).
- Human-readable log: \`production/auto-game-in-sleep/journal.md\` (self-contained, last 50 lines are enough to resume)
- Decision audit trail: \`production/auto-game-in-sleep/decisions.md\`
- Test evidence packs: \`production/auto-game-in-sleep/test-runs/\`
- Orchestrator: invoke the \`game-studios:auto-game-in-sleep\` skill (the full pipeline spec is bundled with the plugin)
- Pipeline catalog: bundled with the plugin at \`docs/workflow-catalog.yaml\`
- This block does NOT contain \`state\` / \`current_phase\` / \`last_seen\` — those live only in \`state.json\`.

### Recovery Protocol (run immediately after compaction or new conversation)

1. **Resume the orchestrator.** Your conversation history has been summarized. Invoke the \`game-studios:auto-game-in-sleep\` skill via the Skill tool NOW, before any other action. Do NOT rely on your summary's memory of the pipeline — the steps, behavior rules, and acceptance definitions live in the skill.
2. Read \`production/auto-game-in-sleep/state.json\` — \`status\`, \`current_phase\`, \`current_step\`, \`iterations\`, \`stale_count\`, \`blocked\`, \`steps[]\`. If it does not exist, the run has not started; follow the skill's Phase 0 to create it.
3. Read \`production/auto-game-in-sleep/journal.md\` (last 50 lines) — self-contained progress; also scan \`decisions.md\` for recent overrides.
4. If \`state.json\` \`status == "running"\`: resume the pipeline at the first \`steps[]\` entry whose \`status != "accepted"\` (re-verify any \`done\` without evidence). Follow the orchestrator skill, step-by-step. Do not stop for user questions.
5. Heartbeat discipline: at the START of every pipeline step, update \`state.json\` \`last_seen\`/\`current_phase\`/\`current_step\` and append a self-contained entry to \`journal.md\` before any long or crash-prone work — so the next compaction finds the true position in the state file, not in this AGENTS.md block.

### Rules while the orchestrator is active

- The Decision Protocol in \`auto-game-in-sleep\` suspends the \`Question -> Options -> Decision -> Draft -> Approval\` gate in this file's Collaboration Protocol. Decisions are made autonomously and appended to \`decisions.md\` (template: Context / Options / Chose / Override).
- Unattended commits allowed: commit locally as workflow skills prescribe (checkpoint commits are bookkeeping, not publishing). \`git push\`, force-anything, and deleting user-authored content outside \`production/auto-game-in-sleep/\` remain forbidden — publishing stays a human act.
- Never mark a step \`accepted\` without evidence (review report / test record / catalog artifact — see skill § Phase 0 / Steps definition).
- \`journal.md\` entries must be self-contained (what was attempted, what is next, which paths matter) so a compacted session can resume from the journal alone.
- Invoke pipeline skills via the Skill tool (e.g. \`game-studios:setup-engine\`, \`game-studios:design-system\`); reading a SKILL.md with Read is for inspection only and never substitutes for invocation. Do not re-implement a skill's workflow by hand from its prose.

<!-- initialized: $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date) — rerun the init skill to refresh -->
$ANCHOR_END
ANCHOREOF
}

ensure_agents_md() {
  agents="$WS/AGENTS.md"
  if [ ! -f "$agents" ]; then
    if [ $DRY -eq 0 ]; then
      {
        tr -d '\r' < "$ASSETS/AGENTS.template.md"
        printf '\n%s\n' "$(print_anchor)"
      } > "$agents"
    fi
    say "[created] AGENTS.md (template + anchor)"
    return
  fi
  count=$(grep -cF "$ANCHOR_BEGIN" "$agents" || true)
  if [ "$count" -gt 1 ]; then
    die "multiple anchor blocks in AGENTS.md — dedupe manually before rerunning"
  fi
  if [ "$count" -eq 1 ]; then
    old_block="$(awk -v b="$ANCHOR_BEGIN" -v e="$ANCHOR_END" '
      index($0, b) { inblk = 1 }
      inblk { print }
      inblk && index($0, e) { inblk = 0 }
    ' "$agents")"
    new_block="$(print_anchor)"
    # Compare ignoring the initialized timestamp line.
    old_cmp="$(printf '%s\n' "$old_block" | grep -v '^<!-- initialized:')"
    new_cmp="$(printf '%s\n' "$new_block" | grep -v '^<!-- initialized:')"
    if [ "$old_cmp" = "$new_cmp" ]; then
      say "[skipped] AGENTS.md anchor (up to date)"
      return
    fi
    if [ $DRY -eq 0 ]; then
      stripped="$(strip_anchor "$agents")"
      printf '%s\n\n%s\n' "$stripped" "$new_block" > "$agents"
    fi
    say "[updated] AGENTS.md anchor (refreshed)"
  else
    if [ $DRY -eq 0 ]; then
      existing="$(cat "$agents")"
      printf '%s\n\n%s\n' "$existing" "$(print_anchor)" > "$agents"
    fi
    say "[updated] AGENTS.md (anchor appended)"
  fi
}

ensure_gitignore() {
  gi="$WS/.gitignore"
  if [ -f "$gi" ] && grep -qF "$GITIGNORE_BEGIN" "$gi"; then
    say "[skipped] .gitignore managed block (already present)"
    return
  fi
  if [ -f "$gi" ]; then
    if [ $DRY -eq 0 ]; then
      existing="$(cat "$gi")"
      printf '%s\n\n%s\n' "$existing" "$(tr -d '\r' < "$ASSETS/gitignore-block.txt")" > "$gi"
    fi
    say "[updated] .gitignore (managed block appended)"
  else
    if [ $DRY -eq 0 ]; then
      tr -d '\r' < "$ASSETS/gitignore-block.txt" > "$gi"
    fi
    say "[created] .gitignore (managed block)"
  fi
}

# ── main ──────────────────────────────────────────────────────────────────
echo "Game Studios init [$MODE]"
echo "  plugin root : $PLUGIN_ROOT"
echo "  workspace   : $WS"
echo ""

ensure_dirs
copy_file "$PLUGIN_ROOT/docs/technical-preferences.md" ".studio/technical-preferences.md"
copy_file "$PLUGIN_ROOT/docs/registry/architecture.yaml" "docs/registry/architecture.yaml"
copy_file "$PLUGIN_ROOT/docs/architecture/tr-registry.yaml" "docs/architecture/tr-registry.yaml"
copy_tree "$PLUGIN_ROOT/rules" ".studio/rules"
copy_tree "$PLUGIN_ROOT/rules" ".zcode/rules"
copy_tree "$PLUGIN_ROOT/rules" ".claude/rules"
copy_file "$ASSETS/settings.json" ".zcode/settings.json"
copy_file "$ASSETS/settings.json" ".claude/settings.json"
copy_file "$ASSETS/statusline.sh" ".studio/statusline.sh"
ensure_agents_md
ensure_gitignore

echo ""
if [ -f "$WS/.studio/technical-preferences.md" ]; then
  say "hooks marker : .studio/technical-preferences.md OK"
else
  say "hooks marker : MISSING (hooks stay dormant until /game-studios:setup-engine run)"
fi
if [ "$MODE" != "APPLY" ]; then
  say "no changes were written"
fi
