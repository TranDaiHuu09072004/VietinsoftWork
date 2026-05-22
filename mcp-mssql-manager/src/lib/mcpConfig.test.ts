import { describe, expect, it } from 'vitest';
import type { ConnectionProfile } from '../types';
import { mergeRootMcpConfig, mergeVsCodeMcpConfig } from './mcpConfig';

const profile: ConnectionProfile = {
  id: 'profile-1',
  name: 'Test',
  serverName: 'mssql-vietinsoft',
  server: 'localhost',
  port: '1433',
  database: 'Demo',
  user: 'sa',
  packageName: '@executeautomation/database-server',
  passwordSecretKey: 'profile-1',
  createdAt: '2026-05-22T00:00:00.000Z',
  updatedAt: '2026-05-22T00:00:00.000Z',
  lastTestStatus: 'unknown',
};

describe('mcp config merge', () => {
  it('merges VS Code config without removing existing servers', () => {
    const merged = mergeVsCodeMcpConfig(
      {
        servers: {
          other: {
            type: 'stdio',
            command: 'node',
            args: ['server.js'],
          },
        },
      },
      profile,
    );

    expect(merged.servers.other).toBeDefined();
    expect(merged.servers['mssql-vietinsoft'].type).toBe('stdio');
    expect(merged.servers['mssql-vietinsoft'].args).toContain('${env:MSSQL_SERVER}');
  });

  it('merges root config without removing existing servers', () => {
    const merged = mergeRootMcpConfig(
      {
        mcpServers: {
          other: {
            command: 'node',
            args: ['server.js'],
          },
        },
      },
      profile,
    );

    expect(merged.mcpServers.other).toBeDefined();
    expect(merged.mcpServers['mssql-vietinsoft'].args).toContain('${MSSQL_SERVER}');
  });
});
