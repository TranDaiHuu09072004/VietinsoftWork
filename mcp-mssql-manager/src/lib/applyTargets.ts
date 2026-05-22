import { appConfigDir, homeDir } from '@tauri-apps/api/path';
import { mkdir, readTextFile, writeTextFile } from '@tauri-apps/plugin-fs';
import type { ConnectionProfile, RootMcpConfig, ToolTarget, ToolTargetId, VsCodeMcpConfig } from '../types';
import { mergeRootMcpConfig, mergeVsCodeMcpConfig } from './mcpConfig';

interface ApplyTargetResult {
  targetId: ToolTargetId;
  success: boolean;
  message: string;
  filePath?: string;
  backupPath?: string;
}

interface ApplyOptions {
  profile: ConnectionProfile;
  targets: ToolTarget[];
  password?: string;
}

type JsonObject = Record<string, unknown>;

export async function applyEnabledTargets({ profile, targets, password = '' }: ApplyOptions): Promise<ApplyTargetResult[]> {
  const enabledTargets = targets.filter((target) => target.enabled);

  if (enabledTargets.length === 0) {
    return [
      {
        targetId: 'vscode-workspace',
        success: false,
        message: 'No target selected. Tick at least one IDE target before applying.',
      },
    ];
  }

  const results: ApplyTargetResult[] = [];
  for (const target of enabledTargets) {
    try {
      results.push(await applyTarget(target.id, profile, password));
    } catch (error) {
      results.push({
        targetId: target.id,
        success: false,
        message: `${target.label}: ${String(error)}`,
      });
    }
  }

  return results;
}

async function applyTarget(targetId: ToolTargetId, profile: ConnectionProfile, password: string): Promise<ApplyTargetResult> {
  switch (targetId) {
    case 'vscode-workspace':
      return applyVsCodeWorkspace(profile, password);
    case 'root-mcp':
      return applyRootMcp(profile, password);
    case 'claude':
      return applyClaude(profile, password);
    case 'antigravity-custom':
      return applyAntigravity(profile, password);
    default:
      return {
        targetId,
        success: false,
        message: `Unsupported target: ${targetId}`,
      };
  }
}

async function applyVsCodeWorkspace(profile: ConnectionProfile, password: string): Promise<ApplyTargetResult> {
  const filePath = '.vscode/mcp.json';
  const existing = await readJsonIfExists<Partial<VsCodeMcpConfig>>(filePath);
  const merged = mergeVsCodeMcpConfig(existing, profile, password);
  const backupPath = await writeJsonWithBackup(filePath, merged);

  return {
    targetId: 'vscode-workspace',
    success: true,
    filePath,
    backupPath,
    message: `VS Code workspace MCP config updated: ${filePath}. Reload VS Code or refresh MCP servers if the new server is not visible immediately.`,
  };
}

async function applyRootMcp(profile: ConnectionProfile, password: string): Promise<ApplyTargetResult> {
  const filePath = '.mcp.json';
  const existing = await readJsonIfExists<Partial<RootMcpConfig>>(filePath);
  const merged = mergeRootMcpConfig(existing, profile, password);
  const backupPath = await writeJsonWithBackup(filePath, merged);

  return {
    targetId: 'root-mcp',
    success: true,
    filePath,
    backupPath,
    message: `Root MCP config updated: ${filePath}.`,
  };
}

async function applyClaude(profile: ConnectionProfile, password: string): Promise<ApplyTargetResult> {
  const baseDir = await appConfigDir();
  const filePath = `${baseDir}Claude/claude_desktop_config.json`;
  const existing = await readJsonIfExists<Partial<RootMcpConfig>>(filePath);
  const merged = mergeRootMcpConfig(existing, profile, password);
  const backupPath = await writeJsonWithBackup(filePath, merged);

  return {
    targetId: 'claude',
    success: true,
    filePath,
    backupPath,
    message: `Claude MCP config updated: ${filePath}. Restart Claude to load the new MCP server.`,
  };
}

async function applyAntigravity(profile: ConnectionProfile, password: string): Promise<ApplyTargetResult> {
  const home = await homeDir();
  const filePath = `${home}.antigravity/mcp.json`;
  const existing = await readJsonIfExists<Partial<RootMcpConfig>>(filePath);
  const merged = mergeRootMcpConfig(existing, profile, password);
  const backupPath = await writeJsonWithBackup(filePath, merged);

  return {
    targetId: 'antigravity-custom',
    success: true,
    filePath,
    backupPath,
    message: `Antigravity MCP config updated: ${filePath}. Restart Antigravity or reload its MCP config if needed.`,
  };
}

async function readJsonIfExists<T extends JsonObject>(filePath: string): Promise<T | undefined> {
  try {
    const text = await readTextFile(filePath);
    if (!text.trim()) return undefined;
    return JSON.parse(text) as T;
  } catch (error) {
    if (isMissingFileError(error)) return undefined;
    throw new Error(`Cannot read or parse ${filePath}: ${String(error)}`);
  }
}

async function writeJsonWithBackup(filePath: string, value: unknown): Promise<string | undefined> {
  await ensureParentDirectory(filePath);
  const backupPath = await backupIfExists(filePath);
  await writeTextFile(filePath, `${JSON.stringify(value, null, 2)}\n`);
  return backupPath;
}

async function backupIfExists(filePath: string): Promise<string | undefined> {
  try {
    const current = await readTextFile(filePath);
    const backupPath = `${filePath}.${toBackupStamp(new Date())}.bak`;
    await writeTextFile(backupPath, current);
    return backupPath;
  } catch (error) {
    if (isMissingFileError(error)) return undefined;
    throw new Error(`Cannot create backup for ${filePath}: ${String(error)}`);
  }
}

async function ensureParentDirectory(filePath: string): Promise<void> {
  const normalized = filePath.replace(/\\/g, '/');
  const slashIndex = normalized.lastIndexOf('/');
  if (slashIndex <= 0) return;

  const dirPath = normalized.slice(0, slashIndex);
  await mkdir(dirPath, { recursive: true });
}

function isMissingFileError(error: unknown): boolean {
  const message = String(error).toLowerCase();
  return message.includes('not found') || message.includes('no such file') || message.includes('cannot find') || message.includes('os error 2');
}

function toBackupStamp(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0');
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}_${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}
