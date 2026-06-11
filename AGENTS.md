# AGENTS.md - Codex startup rules for VietinsoftWork

This workspace is a ParadiseHR / Vietinsoft knowledge base. At the start of every session in this repository, the agent must read these files before answering project-related requests:

1. `UserProfile.md` - user context, language, and communication style.
2. `CLAUDE.md` - mandatory project rules and workflow.
3. `Knowledge/INDEX.md` - knowledge map and lookup entry point.
4. `Knowledge/99_deprecated.md` - obsolete items that must not be suggested or reused.

Operational rules:

- Respond in Vietnamese. The agent refers to itself as "em" and the user as "anh".
- Keep English identifiers unchanged: table names, column names, procedure names, SQL keywords, code identifiers.
- For ParadiseHR business/data/schema/menu/procedure/UI requests, use `Knowledge/INDEX.md` to choose the relevant knowledge file before giving conclusions.
- Before mentioning or recommending any table, column, procedure, view, menu, or parameter, check `Knowledge/99_deprecated.md`.
- Do not write, modify, delete, commit, or push database/code changes unless the user explicitly requests it in the current turn.
- Do not execute destructive DB actions. Generate reviewable SQL scripts under `SQL script/` instead.
