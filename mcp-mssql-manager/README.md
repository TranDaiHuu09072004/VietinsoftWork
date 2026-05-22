# MCP MSSQL Manager

Desktop GUI for managing MCP MSSQL connection profiles and generating IDE/tool MCP configuration.

## Current scope

- Tauri + React/TypeScript desktop app shell.
- Connection profile form and local in-memory profile history.
- Password bridge to OS secure storage through Tauri commands.
- MCP config preview for:
  - VS Code workspace `.vscode/mcp.json` format.
  - Root `.mcp.json` format.
- Dry-run Apply flow. Real file writes and full MCP process test are planned next.

## Development

```powershell
npm install
npm run dev
npm run test
npm run tauri dev
```

## Security note

Do not store database passwords in JSON config files. This app is designed to store passwords through OS secure storage and write MCP config using environment variable placeholders.
