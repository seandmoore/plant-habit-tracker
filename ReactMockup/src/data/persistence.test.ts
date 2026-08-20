import {
  createMemoryAdapter,
  CURRENT_SCHEMA_VERSION,
  loadState,
  migrate,
  saveState,
  STORAGE_KEY,
} from './persistence';
import type { PersistedState } from './persistence';

const valid: PersistedState = {
  version: CURRENT_SCHEMA_VERSION,
  plants: [],
  hasCompletedOnboarding: true,
  colorMode: 'dark',
};

describe('migrate', () => {
  it('accepts state written by this build', () => {
    expect(migrate(valid)).toEqual(valid);
  });

  it('defaults an unrecognised color mode rather than failing the whole read', () => {
    expect(migrate({ ...valid, colorMode: 'neon' })?.colorMode).toBe('system');
  });

  it('refuses a version this build does not understand', () => {
    expect(migrate({ ...valid, version: 2 })).toBeUndefined();
    expect(migrate({ ...valid, version: undefined })).toBeUndefined();
  });

  it('refuses structurally wrong state instead of half-reading it', () => {
    expect(migrate({ ...valid, plants: 'nope' })).toBeUndefined();
    expect(migrate({ ...valid, hasCompletedOnboarding: 'yes' })).toBeUndefined();
    expect(migrate(null)).toBeUndefined();
    expect(migrate('a string')).toBeUndefined();
  });
});

describe('loadState', () => {
  it('returns undefined when nothing has been saved', async () => {
    await expect(loadState(createMemoryAdapter())).resolves.toBeUndefined();
  });

  it('reads back what was written', async () => {
    const adapter = createMemoryAdapter();
    await saveState(adapter, valid);

    await expect(loadState(adapter)).resolves.toEqual(valid);
  });

  it('falls back to samples rather than crashing on corrupt storage', async () => {
    const adapter = createMemoryAdapter({ [STORAGE_KEY]: '{not json' });

    await expect(loadState(adapter)).resolves.toBeUndefined();
  });

  it('survives a storage backend that throws', async () => {
    const adapter = {
      getItem: async () => { throw new Error('unavailable'); },
      setItem: async () => { throw new Error('unavailable'); },
    };

    await expect(loadState(adapter)).resolves.toBeUndefined();
    await expect(saveState(adapter, valid)).resolves.toBeUndefined();
  });
});
