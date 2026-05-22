import type { ConnectionProfile, McpServerConfig, RootMcpConfig, VsCodeMcpConfig } from '../types';

export function buildMcpArgs(profile: Pick<ConnectionProfile, 'serverName' | 'packageName'>, envPrefix: 'plain' | 'vscode'): string[] {
  const env = (name: string) => (envPrefix === 'vscode' ? `\${env:${name}}` : `\${${name}}`);

  return [
    '-y',
    profile.packageName,
    '--sqlserver',
    '--server',
    env('MSSQL_SERVER'),
    '--port',
    env('MSSQL_PORT'),
    '--database',
    env('MSSQL_DATABASE'),
    '--user',
    env('MSSQL_USER'),
    '--password',
    env('MSSQL_PASSWORD'),
  ];
}

export function buildVsCodeServerConfig(profile: ConnectionProfile): McpServerConfig {
  return {
    type: 'stdio',
    command: 'npx',
    args: buildMcpArgs(profile, 'vscode'),
  };
}

export function buildRootServerConfig(profile: ConnectionProfile): McpServerConfig {
  return {
    command: 'npx',
    args: buildMcpArgs(profile, 'plain'),
  };
}

export function mergeVsCodeMcpConfig(existing: Partial<VsCodeMcpConfig> | undefined, profile: ConnectionProfile): VsCodeMcpConfig {
  return {
    servers: {
      ...(existing?.servers ?? {}),
      [profile.serverName]: buildVsCodeServerConfig(profile),
    },
  };
}

export function mergeRootMcpConfig(existing: Partial<RootMcpConfig> | undefined, profile: ConnectionProfile): RootMcpConfig {
  return {
    mcpServers: {
      ...(existing?.mcpServers ?? {}),
      [profile.serverName]: buildRootServerConfig(profile),
    },
  };
}
