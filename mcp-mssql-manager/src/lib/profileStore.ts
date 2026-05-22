import type { ConnectionProfile } from '../types';

const STORAGE_KEY = 'mcp-mssql-manager.profiles.v1';
const ACTIVE_PROFILE_KEY = 'mcp-mssql-manager.activeProfileId.v1';

export interface StoredProfileState {
  profiles: ConnectionProfile[];
  activeProfileId: string | null;
}

export function loadStoredProfileState(): StoredProfileState {
  try {
    const rawProfiles = window.localStorage.getItem(STORAGE_KEY);
    const profiles = rawProfiles ? (JSON.parse(rawProfiles) as ConnectionProfile[]) : [];
    const activeProfileId = window.localStorage.getItem(ACTIVE_PROFILE_KEY);

    return {
      profiles: Array.isArray(profiles) ? profiles : [],
      activeProfileId,
    };
  } catch {
    return {
      profiles: [],
      activeProfileId: null,
    };
  }
}

export function saveStoredProfileState(profiles: ConnectionProfile[], activeProfileId: string | null): void {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(profiles));

  if (activeProfileId) {
    window.localStorage.setItem(ACTIVE_PROFILE_KEY, activeProfileId);
  } else {
    window.localStorage.removeItem(ACTIVE_PROFILE_KEY);
  }
}

export function findDuplicateProfile(profiles: ConnectionProfile[], profile: Pick<ConnectionProfile, 'serverName' | 'server' | 'port' | 'database' | 'user'>): ConnectionProfile | undefined {
  return profiles.find(
    (item) =>
      sameText(item.serverName, profile.serverName) &&
      sameText(item.server, profile.server) &&
      item.port.trim() === profile.port.trim() &&
      sameText(item.database, profile.database) &&
      sameText(item.user, profile.user),
  );
}

function sameText(left: string, right: string): boolean {
  return left.trim().toLowerCase() === right.trim().toLowerCase();
}
