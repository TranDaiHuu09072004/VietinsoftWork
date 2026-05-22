import type { ConnectionProfileDraft, ToolTarget } from '../types';

export const DEFAULT_SERVER_NAME = 'mssql-vietinsoft';
export const DEFAULT_PACKAGE_NAME = '@executeautomation/database-server';

export const defaultProfileDraft: ConnectionProfileDraft = {
  name: 'Vietinsoft Pay',
  serverName: DEFAULT_SERVER_NAME,
  server: '192.168.11.51',
  port: '6688',
  database: 'Vietinsoft_Pay',
  user: 'ai.sa',
  password: '',
  packageName: DEFAULT_PACKAGE_NAME,
};

export const defaultTargets: ToolTarget[] = [
  {
    id: 'vscode-workspace',
    label: 'VS Code workspace',
    description: 'Write .vscode/mcp.json with concrete profile values.',
    status: 'detected',
    enabled: true,
  },
  {
    id: 'root-mcp',
    label: 'Root .mcp.json',
    description: 'Write project-level .mcp.json with concrete profile values.',
    status: 'detected',
    enabled: true,
  },
  {
    id: 'claude',
    label: 'Claude',
    description: 'Write Claude Desktop config at the OS app config location.',
    status: 'detected',
    enabled: false,
  },
  {
    id: 'antigravity-custom',
    label: 'Antigravity custom JSON',
    description: 'Write MCP config at ~/.antigravity/mcp.json.',
    status: 'detected',
    enabled: false,
  },
];
