# Game Studios Plugin

The entire Game Studios multi-agent game development framework — 51 specialist
agents, 77 workflow skills, and guarded automation hooks — packaged as a single
Claude Code plugin. Runs on any host implementing the Claude Code plugin spec
(Claude Code, ZCode, and other compatible hosts).

Development home & first dogfood workspace:
[ZCode-Game-Studios](https://github.com/HunLuanZhiZhu/ZCode-Game-Studios)

## Install

1. `/plugin marketplace add <path-to-Game-Studios-Plugin>`
2. `/plugin install game-studios@game-studios-plugin`
3. Start a new session (hook config is snapshotted at session start).

## Layout

| Path | Contents |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (name: `game-studios`) |
| `.claude-plugin/marketplace.json` | Self-distribution wrapper (repo root = plugin source) |
| `hooks/` | `hooks.json` + 14 guarded scripts (session context, commit/push guards, asset checks, audit trail) |
| `agents/` | 51 specialist agents (directors, programmers, designers, QA, engine specialists) |
| `skills/` | 77 workflow skills (concept → design → dev → QA → release, incl. `auto-game-in-sleep` orchestrator) |

## Roadmap

- [ ] Phase 0 — verify self-reference marketplace install (`source: "./"`) and
      skills/agents discovery in Claude Code + ZCode; verify `${CLAUDE_PLUGIN_ROOT}`
      usability inside SKILL.md bodies
- [ ] Phase 1 — packaging bridge: `build-plugin.sh` syncs agents/skills/hooks/docs
      from the dev repo (dev repo stays untouched)
- [ ] Phase 2 — path decoupling: split framework docs vs per-project config,
      rewrite workspace paths in 47 SKILL.md files, `/gs-init` scaffolder
- [ ] Phase 3 — skill-name aliasing, rules strategy (SessionStart hook injection),
      clean-room E2E install test, CI packaging
