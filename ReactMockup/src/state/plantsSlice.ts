import { createSamplePlants } from '@/data/sampleCollection';
import type { PersistedState } from '@/data/persistence';
import { CURRENT_SCHEMA_VERSION } from '@/data/persistence';
import { createId } from '@/domain/id';
import type {
  CareEvent,
  ColorMode,
  LightLevel,
  PlantEnvironment,
  PlantSpecies,
  UserPlant,
  WaterUnit,
} from '@/domain/types';

export interface PlantState extends PersistedState {
  /** False until storage has been read, so the UI never flashes samples over saved data. */
  hydrated: boolean;
}

export type PlantAction =
  | { type: 'hydrated'; state?: PersistedState }
  | { type: 'plantAdded'; plant: UserPlant }
  | { type: 'plantUpdated'; plantId: string; patch: Partial<UserPlant> }
  | { type: 'plantDeleted'; plantId: string }
  | { type: 'careEventLogged'; plantId: string; event: CareEvent }
  | { type: 'onboardingSet'; completed: boolean }
  | { type: 'colorModeSet'; colorMode: ColorMode }
  | { type: 'samplesRestored' }
  | { type: 'collectionCleared' };

export const sampleState = (): PersistedState => ({
  version: CURRENT_SCHEMA_VERSION,
  plants: createSamplePlants(),
  hasCompletedOnboarding: true,
  colorMode: 'system',
});

export const initialState = (): PlantState => ({ ...sampleState(), hydrated: false });

export function plantsReducer(state: PlantState, action: PlantAction): PlantState {
  switch (action.type) {
    case 'hydrated':
      return { ...(action.state ?? state), hydrated: true };

    case 'plantAdded':
      return { ...state, plants: [action.plant, ...state.plants] };

    case 'plantUpdated':
      return {
        ...state,
        plants: state.plants.map((plant) =>
          plant.id === action.plantId ? { ...plant, ...action.patch } : plant),
      };

    case 'plantDeleted':
      return { ...state, plants: state.plants.filter((plant) => plant.id !== action.plantId) };

    case 'careEventLogged':
      return {
        ...state,
        plants: state.plants.map((plant) =>
          plant.id === action.plantId
            ? { ...plant, careEvents: [action.event, ...plant.careEvents] }
            : plant),
      };

    case 'onboardingSet':
      return { ...state, hasCompletedOnboarding: action.completed };

    case 'colorModeSet':
      return { ...state, colorMode: action.colorMode };

    case 'samplesRestored':
      return { ...sampleState(), hydrated: true };

    // Clearing keeps onboarding complete: someone testing the empty state should land on it,
    // not be sent back through the intro.
    case 'collectionCleared':
      return { ...state, plants: [], hasCompletedOnboarding: true };
  }
}

export interface NewPlantInput {
  nickname: string;
  species: PlantSpecies;
  environment: PlantEnvironment;
  light: LightLevel;
  locationName: string;
  notes: string;
  photoUri?: string;
  reminderEnabled?: boolean;
  reminderHour?: number;
}

export function buildPlant(input: NewPlantInput, now = new Date()): UserPlant {
  return {
    id: createId('plant'),
    nickname: input.nickname.trim() || input.species.commonName,
    speciesId: input.species.id,
    commonName: input.species.commonName,
    scientificName: input.species.scientificName,
    environment: input.environment,
    light: input.light,
    locationName: input.locationName.trim(),
    dateAdded: now.toISOString(),
    baselineWateringDays: input.species.baselineWateringDays,
    reminderEnabled: input.reminderEnabled ?? false,
    reminderHour: input.reminderHour ?? 9,
    notes: input.notes.trim(),
    photoUri: input.photoUri,
    careEvents: [],
  };
}

export interface WateringInput {
  amount?: number;
  waterUnit?: WaterUnit;
  note?: string;
  timestamp?: string;
}

export function buildWateringEvent(input: WateringInput = {}, now = new Date()): CareEvent {
  return {
    id: createId('event'),
    kind: 'watered',
    timestamp: input.timestamp ?? now.toISOString(),
    // A unit without an amount is noise, so it is only recorded alongside one.
    amount: input.amount,
    waterUnit: input.amount == null ? undefined : input.waterUnit,
    note: input.note?.trim() ?? '',
  };
}

export const persistedSlice = (state: PlantState): PersistedState => ({
  version: CURRENT_SCHEMA_VERSION,
  plants: state.plants,
  hasCompletedOnboarding: state.hasCompletedOnboarding,
  colorMode: state.colorMode,
});
