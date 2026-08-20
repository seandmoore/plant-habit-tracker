import React from 'react';
import { Text } from 'react-native';
import { act, render, screen, waitFor } from '@testing-library/react-native';
import { createMemoryAdapter, CURRENT_SCHEMA_VERSION, STORAGE_KEY } from '@/data/persistence';
import type { StorageAdapter } from '@/data/persistence';
import { starterCatalog } from '@/data/catalog';
import { PlantStoreProvider, usePlantStore } from './PlantStore';
import type { PlantStore } from './PlantStore';

let store: PlantStore;

function Probe() {
  store = usePlantStore();
  return <Text>{`${store.state.hydrated}:${store.state.plants.length}`}</Text>;
}

const renderStore = async (adapter: StorageAdapter) => {
  render(<PlantStoreProvider adapter={adapter}><Probe /></PlantStoreProvider>);
  await waitFor(() => expect(store.state.hydrated).toBe(true));
};

describe('PlantStoreProvider', () => {
  it('hydrates from storage before exposing state', async () => {
    const stored = JSON.stringify({
      version: CURRENT_SCHEMA_VERSION,
      plants: [],
      hasCompletedOnboarding: false,
      colorMode: 'dark',
    });
    await renderStore(createMemoryAdapter({ [STORAGE_KEY]: stored }));

    expect(store.state.plants).toEqual([]);
    expect(store.state.colorMode).toBe('dark');
    expect(store.state.hasCompletedOnboarding).toBe(false);
  });

  it('falls back to the sample collection on a first run', async () => {
    await renderStore(createMemoryAdapter());

    expect(store.state.plants).toHaveLength(3);
    expect(screen.getByText('true:3')).toBeTruthy();
  });

  it('persists a change so the next launch reads it back', async () => {
    const adapter = createMemoryAdapter();
    await renderStore(adapter);

    await act(async () => { store.clearCollection(); });

    await waitFor(async () => {
      const raw = await adapter.getItem(STORAGE_KEY);
      expect(JSON.parse(raw ?? '{}').plants).toEqual([]);
    });
  });

  it('returns the id of a newly added plant so callers can navigate to it', async () => {
    await renderStore(createMemoryAdapter());

    let id = '';
    await act(async () => {
      id = store.addPlant({
        nickname: 'Fern',
        species: starterCatalog[0]!,
        environment: 'indoor',
        light: 'medium',
        locationName: '',
        notes: '',
      });
    });

    expect(store.state.plants.find((plant) => plant.id === id)?.nickname).toBe('Fern');
  });

  it('logs a watering through the store rather than from a screen', async () => {
    await renderStore(createMemoryAdapter());
    const target = store.state.plants[0]!;
    const before = target.careEvents.length;

    await act(async () => { store.logWatering(target.id, { amount: 100, waterUnit: 'mL' }); });

    const updated = store.state.plants.find((plant) => plant.id === target.id)!;
    expect(updated.careEvents).toHaveLength(before + 1);
    expect(updated.careEvents[0]).toEqual(expect.objectContaining({ kind: 'watered', amount: 100 }));
  });

  it('throws a clear error when used outside the provider', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => render(<Probe />)).toThrow(/must be used inside PlantStoreProvider/);
    spy.mockRestore();
  });
});
