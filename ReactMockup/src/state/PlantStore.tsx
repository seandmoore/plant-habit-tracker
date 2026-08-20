import React, { createContext, useCallback, useContext, useEffect, useMemo, useReducer } from 'react';
import type { PropsWithChildren } from 'react';
import { asyncStorageAdapter, loadState, saveState } from '@/data/persistence';
import type { StorageAdapter } from '@/data/persistence';
import type { ColorMode, UserPlant } from '@/domain/types';
import {
  buildPlant,
  buildWateringEvent,
  initialState,
  persistedSlice,
  plantsReducer,
} from './plantsSlice';
import type { NewPlantInput, PlantState, WateringInput } from './plantsSlice';

/**
 * A thin React binding over the pure reducer in plantsSlice. Everything worth testing lives
 * in that module; this one only wires storage to dispatch and exposes intent-shaped actions
 * so screens never construct a plant or a care event themselves.
 */
export interface PlantStore {
  state: PlantState;
  addPlant(input: NewPlantInput): string;
  updatePlant(plantId: string, patch: Partial<UserPlant>): void;
  deletePlant(plantId: string): void;
  logWatering(plantId: string, input?: WateringInput): void;
  setOnboarding(completed: boolean): void;
  setColorMode(colorMode: ColorMode): void;
  restoreSamples(): void;
  clearCollection(): void;
}

const PlantStoreContext = createContext<PlantStore | null>(null);

export function PlantStoreProvider({
  children,
  adapter = asyncStorageAdapter,
}: PropsWithChildren<{ adapter?: StorageAdapter }>) {
  const [state, dispatch] = useReducer(plantsReducer, undefined, initialState);

  useEffect(() => {
    let active = true;
    void loadState(adapter).then((stored) => {
      if (active) dispatch({ type: 'hydrated', state: stored });
    });
    return () => { active = false; };
  }, [adapter]);

  useEffect(() => {
    // Writing before hydration would overwrite saved plants with the sample collection.
    if (!state.hydrated) return;
    void saveState(adapter, persistedSlice(state));
  }, [adapter, state]);

  const addPlant = useCallback((input: NewPlantInput) => {
    const plant = buildPlant(input);
    dispatch({ type: 'plantAdded', plant });
    return plant.id;
  }, []);

  const logWatering = useCallback((plantId: string, input: WateringInput = {}) => {
    dispatch({ type: 'careEventLogged', plantId, event: buildWateringEvent(input) });
  }, []);

  const store = useMemo<PlantStore>(() => ({
    state,
    addPlant,
    logWatering,
    updatePlant: (plantId, patch) => dispatch({ type: 'plantUpdated', plantId, patch }),
    deletePlant: (plantId) => dispatch({ type: 'plantDeleted', plantId }),
    setOnboarding: (completed) => dispatch({ type: 'onboardingSet', completed }),
    setColorMode: (colorMode) => dispatch({ type: 'colorModeSet', colorMode }),
    restoreSamples: () => dispatch({ type: 'samplesRestored' }),
    clearCollection: () => dispatch({ type: 'collectionCleared' }),
  }), [addPlant, logWatering, state]);

  return <PlantStoreContext.Provider value={store}>{children}</PlantStoreContext.Provider>;
}

export function usePlantStore(): PlantStore {
  const store = useContext(PlantStoreContext);
  if (!store) throw new Error('usePlantStore must be used inside PlantStoreProvider');
  return store;
}

export function usePlants(): UserPlant[] {
  return usePlantStore().state.plants;
}
