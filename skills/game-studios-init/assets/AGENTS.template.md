# Game Studios Project

Indie game development managed through the **game-studios** plugin
(50+ coordinated subagents, 70+ workflow skills, guarded automation hooks).

## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

## Technical Preferences

@.studio/technical-preferences.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

Framework docs (director gates, coding standards, templates, engine reference,
workflow catalog) are bundled with the plugin under its `docs/` directory.
