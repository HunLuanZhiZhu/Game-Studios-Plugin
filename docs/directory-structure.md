# Directory Structure

```text
/
├── AGENTS.md                    # Master configuration
├── .studio/                    # Project-local config (technical-preferences.md, statusline.sh)
├── src/                         # Game source code (core, gameplay, ai, networking, ui, tools)
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
├── tests/                       # Test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (isolated from src/)
└── production/                  # Production management (sprints, milestones, releases)
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```

> Framework content (agents, skills, hooks, rules, docs — including engine-reference/) is served from the game-studios plugin install directory; the workspace only holds project-local config and outputs. Host settings live at `.zcode/settings.json` (ZCode) and `.claude/settings.json` (Claude Code).
