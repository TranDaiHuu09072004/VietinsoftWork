export type TestStatus = 'unknown' | 'testing' | 'success' | 'failed';

export type ToolTargetId = 'vscode-workspace' | 'root-mcp' | 'claude' | 'antigravity-custom';

export interface ConnectionProfile {
  id: string;
  name: string;
  serverName: string;
  server: string;
  port: string;
  database: string;
  user: string;
  packageName: string;
  passwordSecretKey: string;
  createdAt: string;
  updatedAt: string;
  lastTestStatus: TestStatus;
  lastTestMessage?: string;
}

export interface ConnectionProfileDraft {
  name: string;
  serverName: string;
  server: string;
  port: string;
  database: string;
  user: string;
  password: string;
  packageName: string;
}

export interface ToolTarget {
  id: ToolTargetId;
  label: string;
  description: string;
  status: 'detected' | 'needs-setup' | 'unknown';
  enabled: boolean;
}

export interface ApplyResult {
  targetId: ToolTargetId;
  success: boolean;
  message: string;
  backupPath?: string;
}

export interface McpServerConfig {
  command: string;
  args: string[];
  type?: 'stdio';
}

export interface RootMcpConfig {
  mcpServers: Record<string, McpServerConfig>;
}

export interface VsCodeMcpConfig {
  servers: Record<string, McpServerConfig>;
}
