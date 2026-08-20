import AsyncStorage from '@react-native-async-storage/async-storage';
import type { ColorMode, UserPlant } from '@/domain/types';

export const STORAGE_KEY = '@plant-companion/mock-state-v1';
export const CURRENT_SCHEMA_VERSION = 1;

export interface PersistedState {
  version: typeof CURRENT_SCHEMA_VERSION;
  plants: UserPlant[];
  hasCompletedOnboarding: boolean;
  colorMode: ColorMode;
}

/** The storage surface the store depends on, so tests can substitute a plain in-memory map. */
export interface StorageAdapter {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
}

export const asyncStorageAdapter: StorageAdapter = {
  getItem: (key) => AsyncStorage.getItem(key),
  setItem: (key, value) => AsyncStorage.setItem(key, value),
};

export const createMemoryAdapter = (seed: Record<string, string> = {}): StorageAdapter => {
  const store = new Map(Object.entries(seed));
  return {
    getItem: async (key) => store.get(key) ?? null,
    setItem: async (key, value) => void store.set(key, value),
  };
};

const isColorMode = (value: unknown): value is ColorMode =>
  value === 'system' || value === 'light' || value === 'dark';

/**
 * Reads whatever is on disk and returns state this build can use, or undefined to fall back
 * to samples. Unknown or future versions are refused rather than half-read: a preview that
 * silently loads a shape it does not understand is worse than one that starts fresh.
 */
export function migrate(raw: unknown): PersistedState | undefined {
  if (!raw || typeof raw !== 'object') return undefined;
  const candidate = raw as Partial<PersistedState>;

  if (candidate.version !== CURRENT_SCHEMA_VERSION) return undefined;
  if (!Array.isArray(candidate.plants)) return undefined;
  if (typeof candidate.hasCompletedOnboarding !== 'boolean') return undefined;

  return {
    version: CURRENT_SCHEMA_VERSION,
    plants: candidate.plants,
    hasCompletedOnboarding: candidate.hasCompletedOnboarding,
    colorMode: isColorMode(candidate.colorMode) ? candidate.colorMode : 'system',
  };
}

export async function loadState(adapter: StorageAdapter): Promise<PersistedState | undefined> {
  try {
    const raw = await adapter.getItem(STORAGE_KEY);
    return raw ? migrate(JSON.parse(raw)) : undefined;
  } catch {
    // Corrupt or unreadable storage falls back to samples rather than blocking launch.
    return undefined;
  }
}

export async function saveState(adapter: StorageAdapter, state: PersistedState): Promise<void> {
  try {
    await adapter.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // A preview that cannot write should keep running; the next write may succeed.
  }
}
