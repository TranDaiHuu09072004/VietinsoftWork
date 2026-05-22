import { invoke } from '@tauri-apps/api/core';
import { CheckCircle2, Database, KeyRound, PlugZap, Save, ShieldCheck, Trash2 } from 'lucide-react';
import { FormEvent, useMemo, useState } from 'react';
import { defaultProfileDraft, defaultTargets } from './lib/defaults';
import { mergeRootMcpConfig, mergeVsCodeMcpConfig } from './lib/mcpConfig';
import { createProfileFromDraft, validateProfileDraft } from './lib/profile';
import { canUseNativeSecureStorage, deleteProfilePassword, saveProfilePassword } from './lib/secureStorage';
import type { ConnectionProfile, ConnectionProfileDraft, TestStatus, ToolTargetId } from './types';

function App() {
  const [draft, setDraft] = useState<ConnectionProfileDraft>(defaultProfileDraft);
  const [profiles, setProfiles] = useState<ConnectionProfile[]>([]);
  const [activeProfileId, setActiveProfileId] = useState<string | null>(null);
  const [targets, setTargets] = useState(defaultTargets);
  const [messages, setMessages] = useState<string[]>(['Ready. Create a profile, test it, then preview/apply IDE configuration.']);

  const activeProfile = useMemo(
    () => profiles.find((profile) => profile.id === activeProfileId) ?? profiles[0],
    [activeProfileId, profiles],
  );

  const preview = useMemo(() => {
    if (!activeProfile) return 'Create or select a profile to preview MCP config.';

    return JSON.stringify(
      {
        vscode: mergeVsCodeMcpConfig(undefined, activeProfile),
        rootMcp: mergeRootMcpConfig(undefined, activeProfile),
      },
      null,
      2,
    );
  }, [activeProfile]);

  function updateDraft(field: keyof ConnectionProfileDraft, value: string) {
    setDraft((current) => ({ ...current, [field]: value }));
  }

  async function addProfile(event: FormEvent) {
    event.preventDefault();
    const errors = validateProfileDraft(draft);
    if (errors.length > 0) {
      setMessages(errors);
      return;
    }

    const profile = createProfileFromDraft(draft);

    try {
      if (draft.password && canUseNativeSecureStorage()) {
        await saveProfilePassword(profile.passwordSecretKey, draft.password);
      }

      setProfiles((current) => [profile, ...current]);
      setActiveProfileId(profile.id);
      setDraft({ ...defaultProfileDraft, password: '' });
      setMessages([
        `Profile "${profile.name}" added.`,
        draft.password && !canUseNativeSecureStorage()
          ? 'Password was not saved because native secure storage is available only inside the Tauri app runtime.'
          : 'Password is stored in OS secure storage when running inside Tauri.',
      ]);
    } catch (error) {
      setMessages([`Cannot save profile password: ${String(error)}`]);
    }
  }

  async function removeProfile(profile: ConnectionProfile) {
    try {
      if (canUseNativeSecureStorage()) {
        await deleteProfilePassword(profile.passwordSecretKey);
      }
    } catch (error) {
      setMessages([`Profile removed, but password cleanup failed: ${String(error)}`]);
    }

    setProfiles((current) => current.filter((item) => item.id !== profile.id));
    if (activeProfileId === profile.id) setActiveProfileId(null);
  }

  async function testConnection() {
    if (!activeProfile) {
      setMessages(['Select a profile before testing.']);
      return;
    }

    setProfiles((current) => markProfileTest(current, activeProfile.id, 'testing', 'Testing MCP connection...'));

    try {
      const result = await invoke<{ success: boolean; message: string }>('test_mcp_connection');
      setProfiles((current) => markProfileTest(current, activeProfile.id, result.success ? 'success' : 'failed', result.message));
      setMessages([result.message]);
    } catch (error) {
      const message = `MCP test failed: ${String(error)}`;
      setProfiles((current) => markProfileTest(current, activeProfile.id, 'failed', message));
      setMessages([message]);
    }
  }

  function toggleTarget(targetId: ToolTargetId) {
    setTargets((current) => current.map((target) => (target.id === targetId ? { ...target, enabled: !target.enabled } : target)));
  }

  function dryRunApply() {
    if (!activeProfile) {
      setMessages(['Select a profile before applying configuration.']);
      return;
    }

    const enabledTargets = targets.filter((target) => target.enabled).map((target) => target.label);
    setMessages([
      'Dry run only: write adapters are not enabled yet.',
      `Selected profile: ${activeProfile.name}`,
      `Targets: ${enabledTargets.length ? enabledTargets.join(', ') : 'none'}`,
      'Preview JSON is shown in the right panel. No file was modified.',
    ]);
  }

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <Database size={28} />
          <div>
            <h1>MCP MSSQL Manager</h1>
            <span>Connection profiles for MCP IDE tools</span>
          </div>
        </div>

        <section className="panel profile-list">
          <h2>Connection history</h2>
          {profiles.length === 0 ? <p className="muted">No profile yet.</p> : null}
          {profiles.map((profile) => (
            <button
              type="button"
              key={profile.id}
              className={profile.id === activeProfile?.id ? 'profile-card active' : 'profile-card'}
              onClick={() => setActiveProfileId(profile.id)}
            >
              <strong>{profile.name}</strong>
              <span>{profile.user}@{profile.server}:{profile.port}/{profile.database}</span>
              <em data-status={profile.lastTestStatus}>{profile.lastTestStatus}</em>
            </button>
          ))}
        </section>
      </aside>

      <section className="content-grid">
        <section className="panel form-panel">
          <div className="section-title">
            <KeyRound />
            <div>
              <h2>Add or edit connection</h2>
              <p>Passwords are stored through OS secure storage when running as a Tauri app.</p>
            </div>
          </div>

          <form onSubmit={addProfile} className="profile-form">
            <label>
              Profile name
              <input value={draft.name} onChange={(event) => updateDraft('name', event.target.value)} />
            </label>
            <label>
              MCP server name
              <input value={draft.serverName} onChange={(event) => updateDraft('serverName', event.target.value)} />
            </label>
            <label>
              SQL Server
              <input value={draft.server} onChange={(event) => updateDraft('server', event.target.value)} />
            </label>
            <label>
              Port
              <input value={draft.port} onChange={(event) => updateDraft('port', event.target.value)} />
            </label>
            <label>
              Database
              <input value={draft.database} onChange={(event) => updateDraft('database', event.target.value)} />
            </label>
            <label>
              User
              <input value={draft.user} onChange={(event) => updateDraft('user', event.target.value)} />
            </label>
            <label>
              Password
              <input type="password" value={draft.password} onChange={(event) => updateDraft('password', event.target.value)} />
            </label>
            <label>
              MCP package
              <input value={draft.packageName} onChange={(event) => updateDraft('packageName', event.target.value)} />
            </label>

            <div className="button-row">
              <button type="submit" className="primary"><Save size={16} /> Save profile</button>
              <button type="button" onClick={testConnection}><PlugZap size={16} /> Test</button>
              <button type="button" onClick={dryRunApply}><CheckCircle2 size={16} /> Apply dry run</button>
              {activeProfile ? (
                <button type="button" className="danger" onClick={() => removeProfile(activeProfile)}><Trash2 size={16} /> Delete active</button>
              ) : null}
            </div>
          </form>
        </section>

        <section className="panel targets-panel">
          <div className="section-title">
            <ShieldCheck />
            <div>
              <h2>IDE targets</h2>
              <p>Adapters are merge-safe and should create backups before real writes.</p>
            </div>
          </div>

          <div className="targets">
            {targets.map((target) => (
              <label key={target.id} className="target-card">
                <input type="checkbox" checked={target.enabled} onChange={() => toggleTarget(target.id)} />
                <div>
                  <strong>{target.label}</strong>
                  <span>{target.description}</span>
                  <em>{target.status}</em>
                </div>
              </label>
            ))}
          </div>
        </section>

        <section className="panel preview-panel">
          <h2>Config preview</h2>
          <pre>{preview}</pre>
        </section>

        <section className="panel log-panel">
          <h2>Status</h2>
          {messages.map((message, index) => <p key={`${message}-${index}`}>{message}</p>)}
        </section>
      </section>
    </main>
  );
}

function markProfileTest(
  profiles: ConnectionProfile[],
  profileId: string,
  status: TestStatus,
  message: string,
): ConnectionProfile[] {
  return profiles.map((profile) =>
    profile.id === profileId
      ? {
          ...profile,
          lastTestStatus: status,
          lastTestMessage: message,
          updatedAt: new Date().toISOString(),
        }
      : profile,
  );
}

export default App;
