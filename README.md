<div align="center">

# 🎮 Game Studios Plugin

**The entire Game Studios multi-agent game-development framework — packaged as one Claude Code plugin.**

<a href="./READMEch.md"><img src="https://img.shields.io/badge/中文文档-READMEch.md-2563EB?style=for-the-badge" alt="Chinese README"/></a>
<a href="https://github.com/HunLuanZhiZhu/ZCode-Game-Studios"><img src="https://img.shields.io/badge/Dev_Home-ZCode_Game_Studios-181717?style=for-the-badge&logo=github" alt="Dev home"/></a>
<a href="https://github.com/Donchitos/Claude-Code-Game-Studios"><img src="https://img.shields.io/badge/Upstream-Claude_Code_Game_Studios-181717?style=for-the-badge&logo=github" alt="Upstream project"/></a>

<br/>

<img src="https://img.shields.io/badge/Plugin-game--studios-2563EB?style=for-the-badge" alt="Plugin name"/>
<img src="https://img.shields.io/badge/Hosts-Claude_Code_·_ZCode-7C3AED?style=for-the-badge" alt="Hosts"/>
<img src="https://img.shields.io/badge/License-MIT-3DA639?style=for-the-badge" alt="MIT License"/>

</div>

> [!IMPORTANT]
> Derived from **[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** by Donchitos — MIT, attribution preserved.  
> Development home & first dogfood workspace: **[ZCode-Game-Studios](https://github.com/HunLuanZhiZhu/ZCode-Game-Studios)**.  
> Host-neutral: built on the Claude Code plugin spec — **Claude Code** and **ZCode** are both first-class hosts.

---

## ✨ What's inside

<table>
<tr>
<td width="25%" valign="top">

### 🧑‍🤝‍🧑 50+ Agents
A studio hierarchy of directors, leads, and specialists covering design, engineering, art, QA, production, and release — with engine specialists for Godot, Unity, and Unreal.

</td>
<td width="25%" valign="top">

### 🧠 70+ Skills
The full lifecycle: concept → design → development → QA → release. Includes the `auto-game-in-sleep` unattended orchestrator and the `game-studios-init` workspace scaffolder.

</td>
<td width="25%" valign="top">

### 🛡 Guarded Hooks
Session context injection, dangerous-command guards, commit/push validation, asset checks, and an agent audit trail. All self-contained via `${CLAUDE_PLUGIN_ROOT}` — zero configuration.

</td>
<td width="25%" valign="top">

### 📏 Rules & Docs
11 path-scoped coding standards plus framework docs: director gates, 40+ templates, the workflow catalog, and engine references for Godot / Unity / Unreal.

</td>
</tr>
</table>

## 🚀 Install (Claude Code)

Requires [Claude Code](https://claude.com/claude-code) with plugin support. In your game project workspace, run:

```bash
# 1. Register this repo as a plugin marketplace
claude plugin marketplace add HunLuanZhiZhu/Game-Studios-Plugin

# 2. Install the plugin from it
claude plugin install game-studios@game-studios-plugin
```

(Inside a running Claude Code session, the same steps are `/plugin marketplace add HunLuanZhiZhu/Game-Studios-Plugin` and `/plugin install game-studios@game-studios-plugin`.)

After installation:

1. **Restart the session** — hook configuration is snapshotted at session start.
2. **Run `/game-studios-init`** — scaffolds the workspace (see below).
3. **Run `/game-studios:setup-engine`** — pick your engine; this also activates the hooks.

### Codex

The same repo installs into [Codex](https://developers.openai.com/codex) as a portable plugin (root `plugin.json`, Agent Plugins schema 1.0.0):

```bash
# register the repo as a marketplace
codex plugin marketplace add HunLuanZhiZhu/Game-Studios-Plugin
```

Then inside a Codex session, run `/plugins` and install/toggle **game-studios** in the plugin browser. Note that Codex skips plugin hooks until they are reviewed via `/hooks`.

Codex specifics: skills and hooks are consumed natively; **subagents are not a plugin-bundled component in Codex**, so `/game-studios-init` seeds the 51 agents as `.codex/agents/*.toml` (converted from the Claude format, loaded in trusted projects). Path-scoped rules have no native Codex equivalent — the workspace `AGENTS.md` references them.

### ZCode

ZCode (desktop) installs plugins manually through its UI — point it at this repo, then run `/game-studios-init` in the project workspace.

## 🏗 What `game-studios-init` scaffolds

Idempotent, cross-platform (bash + awk), and never overwrites existing files.

| Path | Purpose |
|---|---|
| `.claude/rules/` | 11 path-scoped coding standards — auto-enforced by Claude Code |
| `.claude/settings.json` + `.zcode/settings.json` | Host settings: permission guardrails + status line (dual-written) |
| `.studio/technical-preferences.md` | Per-project tech config; filled by `/setup-engine`; also the **hooks activation marker** |
| `.studio/statusline.sh` | Production-stage status line |
| `AGENTS.md` / `CLAUDE.md` | Standalone entry files for ZCode / Claude Code, each carrying the collaboration protocol and the anti-compression anchor |
| `docs/registry/architecture.yaml`, `docs/architecture/tr-registry.yaml` | Architecture registries (skills append with user approval) |
| directory skeleton + `.gitignore` managed block | `src/ design/ docs/ tests/ tools/ prototypes/ production/*` |

## 🗂 Layout

```
Game-Studios-Plugin/
├── plugin.json                    # Portable manifest (Agent Plugins schema — Codex)
├── mcp.json                       # Portable MCP declaration (Codex)
├── .claude-plugin/plugin.json     # Claude Code manifest (name: game-studios)
├── .claude-plugin/marketplace.json
├── agents/                        # 50+ specialist agents (Claude/ZCode format)
├── codex/agents/                  # the same agents as Codex TOML (generated)
├── skills/                        # 70+ workflow skills
├── hooks/                         # hooks.json + guarded scripts (shared by CC & Codex)
├── rules/                         # 11 path-scoped coding standards (seed source)
├── docs/                          # Framework docs, templates, engine references
├── .mcp.json                      # Blender MCP server (3D asset pipeline)
└── skills/game-studios-init/      # Workspace scaffolder (script + assets)
```

> [!NOTE]
> The bundled `.mcp.json` registers two MCP servers for the asset pipeline:
> - **blender** (`blender-mcp` → `localhost:9876`) — requires `blender-mcp` on
>   your PATH and Blender running with its MCP addon enabled.
> - **open-design** (`mcp/opendesign-mcp.sh`) — a relocatable launcher for the
>   [Open Design](https://opendesign.dev) desktop app's MCP daemon: it resolves
>   the install path and the live sidecar pipe at startup (no hardcoded paths),
>   so only the app needs to be running.
> Otherwise the servers simply stay disconnected and everything else works.

## 🖥 Host compatibility

| Capability | Claude Code | ZCode | Codex |
|---|---|---|---|
| Skills & agents | ✅ `game-studios:<skill>` | ✅ | ✅ skills native; agents via `.codex/agents/` seeds |
| Hooks — guards, context, audit | ✅ full set | ✅ supported subset | ✅ same `hooks/hooks.json` (review via `/hooks`; needs `bash` on PATH) |
| Rules (`.claude/rules/`) | ✅ verified auto-enforcement | ⚠️ imported via `AGENTS.md` | ❌ referenced from `AGENTS.md` (no native path-scoped rules) |
| Status line | ✅ | ✅ | ❌ n/a |

## 🧭 Path conventions

Framework assets referenced from skills and docs use `${CLAUDE_PLUGIN_ROOT}`
(the plugin install directory, per the Claude Code plugin spec). If your host
does not expand that variable inside skill text, resolve the plugin install
directory first — e.g. ZCode caches installed plugins under
`~/.zcode/cli/plugins/cache/<marketplace>/<plugin>/<version>/`.

Per-project paths stay workspace-relative on purpose: `src/`, `design/`,
`production/`, `docs/architecture/` (project output), and
`.studio/technical-preferences.md` (per-project config, scaffolded by
`/game-studios-init`).

## 🗺 Roadmap

- [x] Single-plugin architecture: agents, skills, hooks, rules, docs
- [x] Reference remap: framework paths use `${CLAUDE_PLUGIN_ROOT}`
- [x] `game-studios-init` — idempotent cross-platform workspace scaffolder
- [x] Codex adaptation: portable `plugin.json`/`mcp.json`, agents converted to
      `.codex/agents/*.toml`, shared `hooks/hooks.json`
- [ ] Host verification: plugin discovery (incl. `source: "./"` self-reference),
      skills/agents namespaces, `${CLAUDE_PLUGIN_ROOT}` expansion in SKILL.md bodies
- [ ] Clean-room E2E install test (Claude Code / ZCode / Codex)
- [ ] CI packaging & versioned releases

## 📄 License & attribution

MIT — see [LICENSE](./LICENSE). Framework content derives from **Claude Code
Game Studios** by Donchitos; this plugin packages and extends it for multi-host
use.
