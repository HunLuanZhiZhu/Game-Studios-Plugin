<div align="center">

# 🎮 Game Studios Plugin

**The entire Game Studios game-development framework — 70+ workflow skills, guarded hooks, and 2 bundled MCP servers — packaged as one plugin.**

<a href="./READMEch.md"><img src="https://img.shields.io/badge/中文文档-READMEch.md-2563EB?style=for-the-badge" alt="Chinese README"/></a>
<a href="https://github.com/HunLuanZhiZhu/ZCode-Game-Studios"><img src="https://img.shields.io/badge/Dev_Home-ZCode_Game_Studios-181717?style=for-the-badge&logo=github" alt="Dev home"/></a>
<a href="https://github.com/Donchitos/Claude-Code-Game-Studios"><img src="https://img.shields.io/badge/Upstream-Claude_Code_Game_Studios-181717?style=for-the-badge&logo=github" alt="Upstream project"/></a>

<br/>

<img src="https://img.shields.io/badge/Plugin-game--studios-2563EB?style=for-the-badge" alt="Plugin name"/>
<img src="https://img.shields.io/badge/Hosts-Claude_Code_·_Codex_·_ZCode-7C3AED?style=for-the-badge" alt="Hosts"/>
<img src="https://img.shields.io/badge/License-MIT-3DA639?style=for-the-badge" alt="MIT License"/>

</div>

> [!IMPORTANT]
> Derived from **[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** by Donchitos — MIT, attribution preserved.  
> Development home & first dogfood workspace: **[ZCode-Game-Studios](https://github.com/HunLuanZhiZhu/ZCode-Game-Studios)**.  
> Host-neutral: built on the Claude Code plugin spec — **Claude Code**, **Codex**, and similar-behavior coding agents (**ZCode**) are first-class hosts.

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

### 🛡 Hooks & MCP Servers
Session context injection, dangerous-command guards, commit/push validation, asset checks, and an agent audit trail — all self-contained via `${CLAUDE_PLUGIN_ROOT}`, zero configuration. Two MCP servers ship bundled in the same plugin (install path and endpoint resolved at runtime — no hardcoded paths, see the MCP note below).

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
| `.claude/settings.json` | Host settings for Claude Code: permission guardrails + status line (ZCode reads no project settings file, so none is written for it) |
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
> The bundled `.mcp.json` registers two optional MCP servers for the asset
> pipeline. Neither is required — the framework core works without them:
> - **blender** (`blender-mcp` → `localhost:9876`) — requires `blender-mcp` on
>   your PATH and Blender running with its MCP addon enabled.
> - **open-design-windows** (`mcp/opendesign-mcp.sh`) — a relocatable launcher
>   for the [Open Design](https://open-design.ai) desktop app's MCP daemon. It
>   resolves the install path and the live sidecar pipe at startup (no
>   hardcoded paths). **Windows only** — auto-discovery uses the Windows
>   registry and named pipes; on macOS/Linux configure the open-design MCP
>   server manually (the app can generate its registration) — see
>   https://open-design.ai .
> Otherwise the servers simply stay disconnected and everything else works.

## 🖥 Host compatibility

| Capability | Claude Code | ZCode | Codex |
|---|---|---|---|
| Skills | ✅ `game-studios:<skill>` | ✅ | ✅ native (same SKILL.md format) |
| Agents (subagents) | ✅ `agents/*.md` | ✅ | ⚠️ not plugin-bundled — seeded as `.codex/agents/*.toml` by init |
| Hooks | ✅ full set | ✅ supported subset | ✅ same `hooks/hooks.json` (review via `/hooks`; needs `bash` on PATH) |
| Rules | ✅ native (`.claude/rules/`, verified auto-enforcement) | ✅ via `AGENTS.md` | ✅ via `AGENTS.md` |
| Status line (init-seeded `statusline.sh`) | ✅ via `.claude/settings.json` | ❌ no project settings file | ❌ n/a |
| MCP servers | ✅ `.mcp.json` | ✅ plugin `mcpServers` | ✅ `mcp.json` |

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

## 📄 License & attribution

MIT — see [LICENSE](./LICENSE). Framework content derives from **Claude Code
Game Studios** by Donchitos; this plugin packages and extends it for multi-host
use.
