# Game Studios Plugin

The entire Game Studios multi-agent game development framework — 50+ specialist
agents, 70+ workflow skills, guarded automation hooks, framework docs, and
path-scoped coding rules — packaged as a single Claude Code plugin. Runs on any
host implementing the Claude Code plugin spec (Claude Code, ZCode, and other
compatible hosts).

Development home & first dogfood workspace:
[ZCode-Game-Studios](https://github.com/HunLuanZhiZhu/ZCode-Game-Studios)

## Install

1. `/plugin marketplace add <path-to-Game-Studios-Plugin>`
2. `/plugin install game-studios@game-studios-plugin`
3. Start a new session (hook config is snapshotted at session start).
4. Run `/game-studios-init` in your project workspace to scaffold it
   (directory layout, per-project config, AGENTS.md anchor).

## Layout

| Path | Contents |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (name: `game-studios`) |
| `.claude-plugin/marketplace.json` | Self-distribution wrapper (repo root = plugin source) |
| `hooks/` | `hooks.json` + guarded scripts (session context, commit/push guards, asset checks, audit trail) |
| `agents/` | 50+ specialist agents (directors, programmers, designers, QA, engine specialists) |
| `skills/` | 70+ workflow skills (concept → design → dev → QA → release, incl. `auto-game-in-sleep` orchestrator) |
| `rules/` | 11 path-scoped coding standards (auto-applied where the host supports rules) |
| `docs/` | Framework docs: standards, director gates, 40+ templates, workflow catalog, engine reference (Godot/Unity/Unreal) |

## Path conventions

Framework assets referenced from skills and docs use `${CLAUDE_PLUGIN_ROOT}`
(the plugin install directory, per the Claude Code plugin spec). If your host
does not expand that variable inside skill text, resolve the plugin install
directory first — e.g. ZCode caches installed plugins under
`~/.zcode/cli/plugins/cache/<marketplace>/<plugin>/<version>/`.

Per-project paths stay workspace-relative on purpose: `src/`, `design/`,
`production/`, `docs/architecture/` (project output), and
`.zcode/docs/technical-preferences.md` (per-project config, scaffolded by
`/game-studios-init`).

## Roadmap

- [x] Framework content native to this repo: agents, skills, hooks, docs, rules
- [x] Reference remap: framework paths use `${CLAUDE_PLUGIN_ROOT}`
- [ ] Host verification: plugin discovery (incl. `source: "./"` self-reference),
      skills/agents namespaces, `${CLAUDE_PLUGIN_ROOT}` expansion in SKILL.md bodies
- [x] Host-agnostic scaffolder: `/game-studios-init` (POSIX sh + awk; copies
      per-project seeds, generates AGENTS.md anchor, merges .gitignore)
- [ ] Clean-room E2E install test, CI packaging
