#!/usr/bin/env python3
"""Game Studios workspace scaffolder.

Copies per-project seeds from the game-studios plugin into a game workspace:
directory skeleton, technical preferences (hooks marker file), architecture
registries, host settings (statusline + permissions), path-scoped rules,
AGENTS.md (collaboration protocol + anti-compression anchor), and a managed
.gitignore block.

Idempotent: existing files are NEVER overwritten; only the managed anchor
block in AGENTS.md and the managed .gitignore block are replaced in place.

Usage:
  python init_workspace.py [WORKSPACE_DIR] [--check] [--dry-run]

Exit codes: 0 = ok (or nothing to do), 1 = error.
Stdlib only; works on Windows (Git Bash, PowerShell, cmd) and Linux/macOS.
"""

import argparse
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

PLUGIN_MARKER = ".claude-plugin/plugin.json"
GITIGNORE_BEGIN = "# === Game Studios plugin (managed) ==="
GITIGNORE_END = "# === Game Studios plugin (end managed block) ==="
ANCHOR_BEGIN = "<!-- ZCGS:BEGIN -->"
ANCHOR_END = "<!-- ZCGS:END -->"

# Directories created if missing (workspace-relative).
DIRS = [
    "src",
    "assets",
    "design",
    "design/gdd",
    "docs",
    "docs/architecture",
    "docs/registry",
    "tests",
    "tools",
    "prototypes",
    "production/session-state",
    "production/session-logs",
    "production/sprints",
    "production/milestones",
]

# Single-file seeds: (plugin-relative source, workspace-relative destination).
FILE_COPIES = [
    ("docs/technical-preferences.md", ".zcode/docs/technical-preferences.md"),
    ("docs/registry/architecture.yaml", "docs/registry/architecture.yaml"),
    ("docs/architecture/tr-registry.yaml", "docs/architecture/tr-registry.yaml"),
]

# Directory seeds: whole-tree copy, file-level skip-existing.
DIR_COPIES = [
    ("rules", ".zcode/rules"),
]

# Assets bundled with this skill: (asset name, workspace-relative destination).
ASSET_COPIES = [
    ("settings.json", ".zcode/settings.json"),
    ("statusline.sh", ".zcode/statusline.sh"),
]

ANCHOR_TEMPLATE = """<!-- ZCGS:BEGIN -->
## ZCGS Orchestrator — Anti-Compression Anchor

> Managed by the game-studios plugin's init script. Do not edit this block manually — rerun the init skill to refresh.
> This block is STATIC — it holds instructions and pointers, never live state values.

### State Pointer (live state lives here — this block never holds stale values)

- Run state (machine truth): `production/auto-game-in-sleep/state.json`
  - If it does not exist, the run has not started — create it per the skill's heartbeat discipline (see below).
- Human-readable log: `production/auto-game-in-sleep/journal.md` (self-contained, last 50 lines are enough to resume)
- Decision audit trail: `production/auto-game-in-sleep/decisions.md`
- Test evidence packs: `production/auto-game-in-sleep/test-runs/`
- Orchestrator: invoke the `game-studios:auto-game-in-sleep` skill (the full pipeline spec is bundled with the plugin)
- Pipeline catalog: bundled with the plugin at `docs/workflow-catalog.yaml`
- This block does NOT contain `state` / `current_phase` / `last_seen` — those live only in `state.json`.

### Recovery Protocol (run immediately after compaction or new conversation)

1. **Resume the orchestrator.** Your conversation history has been summarized. Invoke the `game-studios:auto-game-in-sleep` skill via the Skill tool NOW, before any other action. Do NOT rely on your summary's memory of the pipeline — the steps, behavior rules, and acceptance definitions live in the skill.
2. Read `production/auto-game-in-sleep/state.json` — `status`, `current_phase`, `current_step`, `iterations`, `stale_count`, `blocked`, `steps[]`. If the file does not exist, the run has not started; follow the skill's Phase 0 to create it.
3. Read `production/auto-game-in-sleep/journal.md` (last 50 lines) — self-contained progress; also scan `decisions.md` for recent overrides.
4. If `state.json` `status == "running"`: resume the pipeline at the first `steps[]` entry whose `status != "accepted"` (re-verify any `done` without evidence). Follow the orchestrator skill, step-by-step. Do not stop for user questions.
5. Heartbeat discipline: at the START of every pipeline step, update `state.json` `last_seen`/`current_phase`/`current_step` and append a self-contained entry to `journal.md` before any long or crash-prone work — so the next compaction finds the true position in the state file, not in this AGENTS.md block.

### Rules while the orchestrator is active

- The Decision Protocol in `auto-game-in-sleep` suspends the `Question -> Options -> Decision -> Draft -> Approval` gate in this file's Collaboration Protocol. Decisions are made autonomously and appended to `decisions.md` (template: Context / Options / Chose / Override).
- Unattended commits allowed: commit locally as workflow skills prescribe (checkpoint commits are bookkeeping, not publishing). `git push`, force-anything, and deleting user-authored content outside `production/auto-game-in-sleep/` remain forbidden — publishing stays a human act.
- Never mark a step `accepted` without evidence (review report / test record / catalog artifact — see skill § Phase 0 / Steps definition).
- `journal.md` entries must be self-contained (what was attempted, what is next, which paths matter) so a compacted session can resume from the journal alone.
- Invoke pipeline skills via the Skill tool (e.g. `game-studios:setup-engine`, `game-studios:design-system`); reading a SKILL.md with Read is for inspection only and never substitutes for invocation. Do not re-implement a skill's workflow by hand from its prose.

<!-- initialized: {TIMESTAMP} — rerun the init skill to refresh -->
<!-- ZCGS:END -->
"""


def resolve_plugin_root() -> Path:
    """Plugin root = scripts/ -> skill/ -> skills/ -> plugin root."""
    root = Path(__file__).resolve().parents[3]
    if not (root / PLUGIN_MARKER).is_file():
        print(f"error: plugin marker not found at {root / PLUGIN_MARKER}", file=sys.stderr)
        sys.exit(1)
    return root


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def copy_file(src: Path, dst: Path, ws: Path, report) -> None:
    disp = dst.relative_to(ws).as_posix() if dst.is_relative_to(ws) else dst.as_posix()
    if dst.exists():
        report.append(f"[skipped] {disp} (already exists)")
        return
    if not report.dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
    report.append(f"[created] {disp}")


def copy_tree(src: Path, dst: Path, ws: Path, report) -> None:
    for item in sorted(src.rglob("*")):
        if item.is_dir():
            continue
        copy_file(item, dst / item.relative_to(src), ws, report)


def ensure_dirs(ws: Path, report) -> None:
    for d in DIRS:
        target = ws / d
        if target.is_dir():
            report.append(f"[skipped] {d}/ (already exists)")
            continue
        if not report.dry_run:
            target.mkdir(parents=True, exist_ok=True)
        report.append(f"[created] {d}/")


def anchor_block() -> str:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return ANCHOR_TEMPLATE.replace("{TIMESTAMP}", ts)


def ensure_agents_md(ws: Path, assets: Path, report) -> None:
    agents = ws / "AGENTS.md"
    if not agents.exists():
        if not report.dry_run:
            body = (assets / "AGENTS.template.md").read_text(encoding="utf-8")
            write_text(agents, body.rstrip("\n") + "\n\n" + anchor_block() + "\n")
        report.append("[created] AGENTS.md (template + anchor)")
        return
    text = agents.read_text(encoding="utf-8", errors="replace")
    count = text.count(ANCHOR_BEGIN)
    if count > 1:
        print("error: multiple anchor blocks in AGENTS.md — dedupe manually", file=sys.stderr)
        sys.exit(1)
    if count == 1:
        start = text.index(ANCHOR_BEGIN)
        end = text.index(ANCHOR_END) + len(ANCHOR_END)
        old_block = text[start:end]
        new_block = anchor_block()
        # Compare ignoring the initialized timestamp line.
        strip_ts = lambda b: "\n".join(l for l in b.splitlines() if not l.startswith("<!-- initialized:"))
        if strip_ts(old_block) == strip_ts(new_block):
            report.append("[skipped] AGENTS.md anchor (up to date)")
            return
        if not report.dry_run:
            write_text(agents, text[:start] + new_block + text[end:])
        report.append("[updated] AGENTS.md anchor (refreshed)")
    else:
        if not report.dry_run:
            write_text(agents, text.rstrip("\n") + "\n\n" + anchor_block() + "\n")
        report.append("[updated] AGENTS.md (anchor appended)")


def ensure_gitignore(ws: Path, assets: Path, report) -> None:
    gitignore = ws / ".gitignore"
    block = (assets / "gitignore-block.txt").read_text(encoding="utf-8")
    if gitignore.exists():
        text = gitignore.read_text(encoding="utf-8", errors="replace")
        if GITIGNORE_BEGIN in text:
            report.append("[skipped] .gitignore managed block (already present)")
            return
        if not report.dry_run:
            write_text(gitignore, text.rstrip("\n") + "\n\n" + block)
        report.append("[updated] .gitignore (managed block appended)")
    else:
        if not report.dry_run:
            write_text(gitignore, block)
        report.append("[created] .gitignore (managed block)")


class Report(list):
    dry_run = False


def main() -> None:
    parser = argparse.ArgumentParser(description="Game Studios workspace scaffolder")
    parser.add_argument("workspace", nargs="?", default=".", help="workspace directory (default: cwd)")
    parser.add_argument("--check", action="store_true", help="survey only: report what exists and what is missing")
    parser.add_argument("--dry-run", action="store_true", help="plan only: report actions without writing")
    args = parser.parse_args()

    plugin_root = resolve_plugin_root()
    assets = Path(__file__).resolve().parent.parent / "assets"
    ws = Path(args.workspace).resolve()
    ws.mkdir(parents=True, exist_ok=True)

    if ws == plugin_root or plugin_root in ws.parents:
        print("error: refusing to scaffold inside the plugin repo itself", file=sys.stderr)
        sys.exit(1)

    report = Report()
    report.dry_run = args.dry_run or args.check

    mode = "CHECK" if args.check else ("DRY-RUN" if args.dry_run else "APPLY")
    print(f"Game Studios init [{mode}]")
    print(f"  plugin root : {plugin_root}")
    print(f"  workspace   : {ws}")
    print()

    ensure_dirs(ws, report)
    for src_rel, dst_rel in FILE_COPIES:
        copy_file(plugin_root / src_rel, ws / dst_rel, ws, report)
    for src_rel, dst_rel in DIR_COPIES:
        copy_tree(plugin_root / src_rel, ws / dst_rel, ws, report)
    for asset, dst_rel in ASSET_COPIES:
        copy_file(assets / asset, ws / dst_rel, ws, report)
    ensure_agents_md(ws, assets, report)
    ensure_gitignore(ws, assets, report)

    print()
    for line in report:
        print(line)
    print()
    marker = ws / ".zcode/docs/technical-preferences.md"
    print(f"hooks marker : {marker.as_posix()} {'OK' if marker.exists() else 'MISSING (hooks stay dormant until /game-studios:setup-engine run)'}")
    if args.check or args.dry_run:
        print("no changes were written")
    elif any(line.startswith("[error]") for line in report):
        sys.exit(1)


if __name__ == "__main__":
    main()
