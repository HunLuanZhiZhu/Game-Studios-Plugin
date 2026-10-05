---
name: game-studios-init
description: "Initializes a game project workspace for the Game Studios plugin: scaffolds directories, copies per-project seeds (technical-preferences, architecture registries, settings, rules), generates AGENTS.md with the anti-compression anchor, and merges .gitignore. Invoke when the user asks to initialize or set up a new game project, says 初始化/新项目开工, or right after installing the plugin in a fresh workspace."
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# Game Studios Project Initialization

Turns the current workspace into a Game Studios project. Idempotent: safe to
rerun; **existing files are never overwritten** — the managed anchor block in
`AGENTS.md` and the managed block in `.gitignore` are the only content ever
replaced in place. All mechanical work is done by a cross-platform (Windows /
Linux / macOS) POSIX-sh script (bash + awk — the same runtime the hooks already
require), so behavior is identical on every host and every run.

## What the script copies (and why)

| Workspace path | Source | Why |
|---|---|---|
| `.studio/technical-preferences.md` | plugin `docs/technical-preferences.md` | Per-project config with `[TO BE CONFIGURED]` placeholders; filled by `/game-studios:setup-engine`; **marker file that activates all hooks** |
| `.zcode/settings.json` + `.claude/settings.json` (dual-written) + `.studio/statusline.sh` | skill assets | Host plumbing for ZCode and Claude Code: permission guardrails + production-stage status line (statusline script lives in the neutral `.studio/` dir) |
| `.studio/rules/` (11 files) | plugin `rules/` | Path-scoped coding standards (reference copies in the neutral dir) |
| `docs/registry/architecture.yaml` | plugin `docs/registry/architecture.yaml` | Empty scaffold; `/game-studios:architecture-decision` appends with user approval |
| `docs/architecture/tr-registry.yaml` | plugin `docs/architecture/tr-registry.yaml` | Empty scaffold; keeps TR-IDs stable across runs |
| `AGENTS.md` | skill asset template | Collaboration protocol, stack placeholders, anti-compression anchor (created only if missing) |
| directories | — | `src/ assets/ design/ design/gdd/ docs/ docs/architecture/ docs/registry/ tests/ tools/ prototypes/ production/*` |
| `.gitignore` | skill asset block | Framework ignores appended between managed markers |

## Procedure

1. **Survey first.** Check whether `AGENTS.md`, `.studio/`, `src/`, `design/`,
   `docs/` already exist and whether this is a brownfield project. If files
   the script would create already hold user content, confirm scope with the
   user before applying (copies skip existing files, so nothing is lost).
2. **Locate the script**: `scripts/init_workspace.sh` next to this file. The
   script resolves the plugin root from its own location; no environment
   variable is needed. It runs with bash and uses awk only — no sed multiline, no Python.
3. **Run with `--check`** to survey without writing, review the report with
   the user, then run without flags to apply:
   `bash <skill-dir>/scripts/init_workspace.sh "<workspace-dir>"`
4. **Post-run polish** (interactive): put the project name/title into
   `AGENTS.md`; remind the user that `/game-studios:setup-engine` populates
   `.studio/technical-preferences.md` — until then all hooks stay dormant
   by design.
5. **Verify**: the script prints `[created]`/`[skipped]`/`[updated]` per path
   and the hooks-marker status. Confirm `AGENTS.md` contains both
   `<!-- ZCGS:BEGIN -->` and `<!-- ZCGS:END -->`.
6. **Next steps**: `/game-studios:setup-engine` (engine choice) or the full
   onboarding flow (`game-studios:start`).

## Notes

- Brownfield projects: run the script first (it only fills gaps), then
  `game-studios:adopt` for format compliance and migration planning.
- The plugin repo itself is never modified; the workspace owns everything
  created. Refusing to run inside the plugin repo is built into the script.
