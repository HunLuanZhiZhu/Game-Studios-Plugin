<div align="center">

# 🎮 Game Studios Plugin

**把完整的 Game Studios 多智能体游戏开发框架,打包成一个 Claude Code 插件。**

<a href="./README.md"><img src="https://img.shields.io/badge/English-README.md-2563EB?style=for-the-badge" alt="English README"/></a>
<a href="https://github.com/HunLuanZhiZhu/ZCode-Game-Studios"><img src="https://img.shields.io/badge/开发主仓-ZCode_Game_Studios-181717?style=for-the-badge&logo=github" alt="Dev home"/></a>
<a href="https://github.com/Donchitos/Claude-Code-Game-Studios"><img src="https://img.shields.io/badge/上游项目-Claude_Code_Game_Studios-181717?style=for-the-badge&logo=github" alt="Upstream project"/></a>

<br/>

<img src="https://img.shields.io/badge/插件名-game--studios-2563EB?style=for-the-badge" alt="Plugin name"/>
<img src="https://img.shields.io/badge/宿主-Claude_Code_·_ZCode-7C3AED?style=for-the-badge" alt="Hosts"/>
<img src="https://img.shields.io/badge/许可证-MIT-3DA639?style=for-the-badge" alt="MIT License"/>

</div>

> [!IMPORTANT]
> 本插件派生自 Donchitos 的 **[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)**(MIT,保留原作者归属)。  
> 开发主仓与首个实战工作区:**[ZCode-Game-Studios](https://github.com/HunLuanZhiZhu/ZCode-Game-Studios)**。  
> 宿主中立:基于 Claude Code 插件规范构建——**Claude Code** 与 **ZCode** 均为一级支持宿主。

---

## ✨ 里面有什么

<table>
<tr>
<td width="25%" valign="top">

### 🧑‍🤝‍🧑 50+ Agent
工作室式层级:导演、部门负责人与专业 Agent,覆盖设计、工程、美术、QA、生产与发布——含 Godot、Unity、Unreal 三套引擎专家。

</td>
<td width="25%" valign="top">

### 🧠 70+ 技能
覆盖完整生命周期:概念 → 设计 → 开发 → QA → 发布。包含 `auto-game-in-sleep` 无人值守编排器与 `game-studios-init` 工作区脚手架。

</td>
<td width="25%" valign="top">

### 🛡 带守卫的 Hooks
会话上下文注入、危险命令拦截、提交/推送校验、资产检查、Agent 审计日志。全部通过 `${CLAUDE_PLUGIN_ROOT}` 自包含,零配置。

</td>
<td width="25%" valign="top">

### 📏 规则与文档
11 个路径作用域编码规范 + 框架文档:导演门禁、40+ 模板、工作流目录,以及 Godot / Unity / Unreal 引擎参考。

</td>
</tr>
</table>

## 🚀 安装

在你的游戏项目工作区中:

```
/plugin marketplace add <Game-Studios-Plugin 路径>
/plugin install game-studios@game-studios-plugin
```

1. **重启会话** —— hook 配置在会话启动时快照。
2. **运行 `/game-studios-init`** —— 脚手架化工作区(见下表)。
3. **运行 `/game-studios:setup-engine`** —— 选择引擎,同时激活 hooks。

## 🏗 `game-studios-init` 会脚手架什么

幂等、跨平台(bash + awk),并且**永不覆盖已有文件**。

| 路径 | 用途 |
|---|---|
| `.claude/rules/` | 11 个路径作用域编码规范——由 Claude Code 自动强制 |
| `.claude/settings.json` + `.zcode/settings.json` | 宿主设置:权限守卫 + 状态栏(双写) |
| `.studio/technical-preferences.md` | 每项目技术配置;由 `/setup-engine` 填写;同时是 **hooks 激活标记** |
| `.studio/statusline.sh` | 生产阶段状态栏 |
| `AGENTS.md` / `CLAUDE.md` | ZCode / Claude Code 各自独立的入口文件,均携带协作协议与防压缩锚点 |
| `docs/registry/architecture.yaml`、`docs/architecture/tr-registry.yaml` | 架构登记表(技能经用户批准后追加) |
| 目录骨架 + `.gitignore` 管理块 | `src/ design/ docs/ tests/ tools/ prototypes/ production/*` |

## 🗂 目录结构

```
Game-Studios-Plugin/
├── .claude-plugin/plugin.json     # 插件清单(名称:game-studios)
├── .claude-plugin/marketplace.json
├── agents/                        # 50+ 专业 Agent
├── skills/                        # 70+ 工作流技能
├── hooks/                         # hooks.json + 守卫脚本
├── rules/                         # 11 个路径作用域编码规范(种子源)
├── docs/                          # 框架文档、模板、引擎参考
├── .mcp.json                      # Blender MCP 服务器(3D 资产管线)
└── skills/game-studios-init/      # 工作区脚手架(脚本 + 资产)
```

> [!NOTE]
> 内置的 `.mcp.json` 注册了 **Blender MCP 服务器**(`blender-mcp` →
> `localhost:9876`),供 3D 资产管线使用。它要求 PATH 中已安装 `blender-mcp`,
> 且 Blender 已开启其 MCP 插件并运行——否则该服务器只是保持断开,其余功能不受影响。

## 🖥 宿主兼容性

| 能力 | Claude Code | ZCode |
|---|---|---|
| 技能与 Agent | ✅ `game-studios:<skill>` | ✅ |
| Hooks——守卫、上下文、审计 | ✅ 完整集 | ✅ 受支持的子集 |
| 规则(`.claude/rules/`) | ✅ 已验证自动强制 | ⚠️ 不适用——规范改为经 `AGENTS.md` 导入 |
| 状态栏 | ✅ | ✅ |

## 🧭 路径约定

技能与文档引用框架资产时使用 `${CLAUDE_PLUGIN_ROOT}`(即插件安装目录,遵循 Claude Code 插件规范)。如果你的宿主不会在技能正文中展开该变量,请先解析插件安装目录——例如 ZCode 将插件缓存于
`~/.zcode/cli/plugins/cache/<marketplace>/<plugin>/<version>/`。

项目自有路径保持工作区相对:`src/`、`design/`、`production/`、`docs/architecture/`(项目产出),以及
`.studio/technical-preferences.md`(每项目配置,由 `/game-studios-init` 脚手架)。

## 🗺 路线图

- [x] 单插件架构:agents、skills、hooks、rules、docs
- [x] 引用重映射:框架路径统一使用 `${CLAUDE_PLUGIN_ROOT}`
- [x] `game-studios-init` —— 幂等的跨平台工作区脚手架
- [ ] 宿主验证:插件发现(含 `source: "./"` 自引用)、技能/Agent 命名空间、SKILL.md 正文中的 `${CLAUDE_PLUGIN_ROOT}` 展开
- [ ] 干净环境 E2E 安装测试
- [ ] CI 打包与版本化发布

## 📄 许可与归属

MIT —— 见 [LICENSE](./LICENSE)。框架内容派生自 Donchitos 的 **Claude Code Game Studios**;本插件将其打包并扩展为多宿主可用。
