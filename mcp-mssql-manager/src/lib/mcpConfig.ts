import type { ConnectionProfile, McpServerConfig, RootMcpConfig, VsCodeMcpConfig } from '../types';

export function buildMcpArgs(profile: Pick<ConnectionProfile, 'packageName' | 'server' | 'port' | 'database' | 'user'>, password = ''): string[] {
  return [
    '-y',
    profile.packageName,
    '--sqlserver',
    '--server',
    profile.server,
    '--port',
    profile.port,
    '--database',
    profile.database,
    '--user',
    profile.user,
    '--password',
    password,
  ];
}

export function buildVsCodeServerConfig(profile: ConnectionProfile, password = ''): McpServerConfig {
  return {
    type: 'stdio',
    command: 'npx',
    args: buildMcpArgs(profile, password),
  };
}

export function buildRootServerConfig(profile: ConnectionProfile, password = ''): McpServerConfig {
  return {
    command: 'npx',
    args: buildMcpArgs(profile, password),
  };
}

export function mergeVsCodeMcpConfig(existing: Partial<VsCodeMcpConfig> | undefined, profile: ConnectionProfile, password = ''): VsCodeMcpConfig {
  return {
    servers: {
      ...(existing?.servers ?? {}),
      [profile.serverName]: buildVsCodeServerConfig(profile, password),
    },
  };
}

export function mergeRootMcpConfig(existing: Partial<RootMcpConfig> | undefined, profile: ConnectionProfile, password = ''): RootMcpConfig {
  return {
    mcpServers: {
      ...(existing?.mcpServers ?? {}),
      [profile.serverName]: buildRootServerConfig(profile, password),
    },
  };
}
