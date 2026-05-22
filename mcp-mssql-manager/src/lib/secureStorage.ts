import { invoke } from '@tauri-apps/api/core';

export interface SecretPayload {
  profile_id: string;
  password: string;
}

export async function saveProfilePassword(profileId: string, password: string): Promise<void> {
  await invoke('save_profile_password', {
    payload: {
      profile_id: profileId,
      password,
    } satisfies SecretPayload,
  });
}

export async function readProfilePassword(profileId: string): Promise<string> {
  return invoke<string>('read_profile_password', { profileId });
}

export async function deleteProfilePassword(profileId: string): Promise<void> {
  await invoke('delete_profile_password', { profileId });
}

export function canUseNativeSecureStorage(): boolean {
  return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
}
