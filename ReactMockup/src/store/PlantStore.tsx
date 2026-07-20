import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, PropsWithChildren, useCallback, useContext, useEffect, useMemo, useReducer } from 'react';
import { createSampleState } from '@/data/sampleState';
import { createId } from '@/domain/id';
import { CareEvent, ColorMode, LightLevel, PersistedPlantState, PlantEnvironment, PlantSpecies, UserPlant, WaterUnit } from '@/domain/types';

const STORAGE_KEY = '@plant-companion/mock-state-v1';

export interface PlantStoreState extends PersistedPlantState {
  hydrated: boolean;
}

export type PlantAction =
  | { type: 'hydrate'; payload: PersistedPlantState }
  | { type: 'ready' }
  | { type: 'addPlant'; payload: UserPlant }
  | { type: 'updatePlant'; plantId: string; patch: Partial<UserPlant> }
  | { type: 'deletePlant'; plantId: string }
  | { type: 'addCareEvent'; plantId: string; event: CareEvent }
  | { type: 'setOnboarding'; completed: boolean }
  | { type: 'setColorMode'; colorMode: ColorMode }
  | { type: 'resetSamples' }
  | { type: 'clearAll' };

export const initialState = (): PlantStoreState => ({ ...createSampleState(), hydrated: false });

export const plantReducer = (state: PlantStoreState, action: PlantAction): PlantStoreState => {
  switch (action.type) {
    case 'hydrate':
      return { ...action.payload, hydrated: true };
    case 'ready':
      return { ...state, hydrated: true };
    case 'addPlant':
      return { ...state, plants: [action.payload, ...state.plants] };
    case 'updatePlant':
      return { ...state, plants: state.plants.map((plant) => plant.id === action.plantId ? { ...plant, ...action.patch } : plant) };
    case 'deletePlant':
      return { ...state, plants: state.plants.filter((plant) => plant.id !== action.plantId) };
    case 'addCareEvent':
      return {
        ...state,
        plants: state.plants.map((plant) => plant.id === action.plantId
          ? { ...plant, careEvents: [action.event, ...plant.careEvents] }
          : plant),
      };
    case 'setOnboarding':
      return { ...state, hasCompletedOnboarding: action.completed };
    case 'setColorMode':
      return { ...state, colorMode: action.colorMode };
    case 'resetSamples':
      return { ...createSampleState(), hydrated: true };
    case 'clearAll':
      return { ...state, plants: [], hasCompletedOnboarding: true };
  }
};

interface AddPlantInput {
  nickname: string;
  species: PlantSpecies;
  environment: PlantEnvironment;
  light: LightLevel;
  locationName: string;
  notes: string;
  photoUri?: string;
}

interface WaterInput {
  amount?: number;
  waterUnit?: WaterUnit;
  note?: string;
  timestamp?: string;
}

interface PlantStoreValue {
  state: PlantStoreState;
  addPlant(input: AddPlantInput): string;
  updatePlant(plantId: string, patch: Partial<UserPlant>): void;
  deletePlant(plantId: string): void;
  logWatering(plantId: string, input?: WaterInput): void;
  setOnboarding(completed: boolean): void;
  setColorMode(colorMode: ColorMode): void;
  resetSamples(): void;
  clearAll(): void;
}

const PlantStoreContext = createContext<PlantStoreValue | null>(null);

const persistedSlice = (state: PlantStoreState): PersistedPlantState => ({
  version: 1,
  plants: state.plants,
  hasCompletedOnboarding: state.hasCompletedOnboarding,
  colorMode: state.colorMode,
});

const isPersistedState = (value: unknown): value is PersistedPlantState => {
  if (!value || typeof value !== 'object') return false;
  const candidate = value as Partial<PersistedPlantState>;
  return candidate.version === 1 && Array.isArray(candidate.plants) && typeof candidate.hasCompletedOnboarding === 'boolean';
};

export function PlantStoreProvider({ children }: PropsWithChildren) {
  const [state, dispatch] = useReducer(plantReducer, initialState());

  useEffect(() => {
    let active = true;
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (!active) return;
        if (!raw) return dispatch({ type: 'ready' });
        const parsed: unknown = JSON.parse(raw);
        dispatch(isPersistedState(parsed) ? { type: 'hydrate', payload: parsed } : { type: 'ready' });
      })
      .catch(() => active && dispatch({ type: 'ready' }));
    return () => { active = false; };
  }, []);

  useEffect(() => {
    if (!state.hydrated) return;
    void AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(persistedSlice(state)));
  }, [state]);

  const addPlant = useCallback((input: AddPlantInput) => {
    const id = createId('plant');
    dispatch({
      type: 'addPlant',
      payload: {
        id,
        nickname: input.nickname.trim() || input.species.commonName,
        speciesId: input.species.id,
        commonName: input.species.commonName,
        scientificName: input.species.scientificName,
        environment: input.environment,
        light: input.light,
        locationName: input.locationName.trim(),
        dateAdded: new Date().toISOString(),
        baselineWateringDays: input.species.baselineWateringDays,
        reminderEnabled: false,
        reminderHour: 9,
        notes: input.notes.trim(),
        photoUri: input.photoUri,
        careEvents: [],
      },
    });
    return id;
  }, []);

  const updatePlant = useCallback((plantId: string, patch: Partial<UserPlant>) => dispatch({ type: 'updatePlant', plantId, patch }), []);
  const deletePlant = useCallback((plantId: string) => dispatch({ type: 'deletePlant', plantId }), []);
  const logWatering = useCallback((plantId: string, input: WaterInput = {}) => {
    dispatch({
      type: 'addCareEvent',
      plantId,
      event: {
        id: createId('event'),
        kind: 'watered',
        timestamp: input.timestamp ?? new Date().toISOString(),
        amount: input.amount,
        waterUnit: input.amount == null ? undefined : input.waterUnit,
        note: input.note?.trim() ?? '',
      },
    });
  }, []);

  const value = useMemo<PlantStoreValue>(() => ({
    state,
    addPlant,
    updatePlant,
    deletePlant,
    logWatering,
    setOnboarding: (completed) => dispatch({ type: 'setOnboarding', completed }),
    setColorMode: (colorMode) => dispatch({ type: 'setColorMode', colorMode }),
    resetSamples: () => dispatch({ type: 'resetSamples' }),
    clearAll: () => dispatch({ type: 'clearAll' }),
  }), [addPlant, deletePlant, logWatering, state, updatePlant]);

  return <PlantStoreContext.Provider value={value}>{children}</PlantStoreContext.Provider>;
}

export const usePlantStore = (): PlantStoreValue => {
  const value = useContext(PlantStoreContext);
  if (!value) throw new Error('usePlantStore must be used inside PlantStoreProvider');
  return value;
};
