import type { ConnectionProfile, ConnectionProfileDraft } from '../types';

export function createProfileFromDraft(draft: ConnectionProfileDraft): ConnectionProfile {
  const now = new Date().toISOString();
  const id = crypto.randomUUID();

  return {
    id,
    name: draft.name.trim(),
    serverName: draft.serverName.trim(),
    server: draft.server.trim(),
    port: draft.port.trim(),
    database: draft.database.trim(),
    user: draft.user.trim(),
    packageName: draft.packageName.trim(),
    passwordSecretKey: id,
    createdAt: now,
    updatedAt: now,
    lastTestStatus: 'unknown',
  };
}

export function validateProfileDraft(draft: ConnectionProfileDraft): string[] {
  const errors: string[] = [];

  if (!draft.name.trim()) errors.push('Profile name is required.');
  if (!draft.serverName.trim()) errors.push('MCP server name is required.');
  if (!draft.server.trim()) errors.push('SQL Server host is required.');
  if (!draft.port.trim()) errors.push('SQL Server port is required.');
  if (!draft.database.trim()) errors.push('Database is required.');
  if (!draft.user.trim()) errors.push('User is required.');
  if (!draft.packageName.trim()) errors.push('MCP package name is required.');

  return errors;
}

export function maskValue(value: string): string {
  if (!value) return '';
  if (value.length <= 4) return '••••';
  return `${value.slice(0, 2)}••••${value.slice(-2)}`;
}
