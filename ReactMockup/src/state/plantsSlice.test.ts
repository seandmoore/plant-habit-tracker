import { CURRENT_SCHEMA_VERSION } from '@/data/persistence';
import { starterCatalog } from '@/data/catalog';
import {
  buildPlant,
  buildWateringEvent,
  initialState,
  persistedSlice,
  plantsReducer,
  sampleState,
} from './plantsSlice';
import type { PlantState } from './plantsSlice';

const hydrated = (): PlantState => ({ ...sampleState(), hydrated: true });
const species = starterCatalog[0]!;

describe('plantsReducer', () => {
  it('starts un-hydrated so storage is never overwritten before it is read', () => {
    expect(initialState().hydrated).toBe(false);
  });

  it('adopts stored state on hydration', () => {
    const stored = { ...sampleState(), plants: [], hasCompletedOnboarding: false, colorMode: 'dark' as const };
    const next = plantsReducer(initialState(), { type: 'hydrated', state: stored });

    expect(next.hydrated).toBe(true);
    expect(next.plants).toEqual([]);
    expect(next.colorMode).toBe('dark');
  });

  it('keeps the sample collection when there is nothing stored', () => {
    const next = plantsReducer(initialState(), { type: 'hydrated' });

    expect(next.hydrated).toBe(true);
    expect(next.plants).toHaveLength(3);
  });

  it('adds a plant to the front of the collection', () => {
    const plant = buildPlant({ nickname: 'New', species, environment: 'indoor', light: 'medium', locationName: '', notes: '' });
    const next = plantsReducer(hydrated(), { type: 'plantAdded', plant });

    expect(next.plants[0]?.id).toBe(plant.id);
    expect(next.plants).toHaveLength(4);
  });

  it('patches only the named plant', () => {
    const state = hydrated();
    const [first, second] = state.plants as [typeof state.plants[0], typeof state.plants[0]];
    const next = plantsReducer(state, { type: 'plantUpdated', plantId: first.id, patch: { nickname: 'Renamed' } });

    expect(next.plants.find((entry) => entry.id === first.id)?.nickname).toBe('Renamed');
    expect(next.plants.find((entry) => entry.id === second.id)).toEqual(second);
  });

  it('removes a plant and leaves the rest intact', () => {
    const state = hydrated();
    const target = state.plants[0]!;
    const next = plantsReducer(state, { type: 'plantDeleted', plantId: target.id });

    expect(next.plants.some((entry) => entry.id === target.id)).toBe(false);
    expect(next.plants).toHaveLength(2);
  });

  it('logs a care event against one plant without touching another', () => {
    const state = hydrated();
    const [first, second] = state.plants as [typeof state.plants[0], typeof state.plants[0]];
    const event = buildWateringEvent({ amount: 200, waterUnit: 'mL' });
    const next = plantsReducer(state, { type: 'careEventLogged', plantId: first.id, event });

    expect(next.plants.find((entry) => entry.id === first.id)?.careEvents[0]).toEqual(event);
    expect(next.plants.find((entry) => entry.id === second.id)?.careEvents).toEqual(second.careEvents);
  });

  it('ignores a care event for a plant that no longer exists', () => {
    const state = hydrated();
    const next = plantsReducer(state, { type: 'careEventLogged', plantId: 'gone', event: buildWateringEvent() });

    expect(next.plants).toEqual(state.plants);
  });

  it('clears the collection but keeps onboarding complete', () => {
    const next = plantsReducer(hydrated(), { type: 'collectionCleared' });

    expect(next.plants).toEqual([]);
    expect(next.hasCompletedOnboarding).toBe(true);
  });

  it('restores fresh samples over a cleared collection', () => {
    const cleared = plantsReducer(hydrated(), { type: 'collectionCleared' });
    const restored = plantsReducer(cleared, { type: 'samplesRestored' });

    expect(restored.plants.length).toBeGreaterThanOrEqual(3);
    expect(restored.hydrated).toBe(true);
  });

  it('replays onboarding without discarding plants', () => {
    const next = plantsReducer(hydrated(), { type: 'onboardingSet', completed: false });

    expect(next.hasCompletedOnboarding).toBe(false);
    expect(next.plants).toHaveLength(3);
  });

  it('records the chosen color mode', () => {
    expect(plantsReducer(hydrated(), { type: 'colorModeSet', colorMode: 'dark' }).colorMode).toBe('dark');
  });
});

describe('buildPlant', () => {
  const base = { species, environment: 'indoor' as const, light: 'medium' as const, locationName: '  Shelf  ', notes: '  Note  ' };

  it('copies the species care baseline onto the plant', () => {
    const plant = buildPlant({ ...base, nickname: 'Moss' });

    expect(plant.baselineWateringDays).toBe(species.baselineWateringDays);
    expect(plant.speciesId).toBe(species.id);
    expect(plant.commonName).toBe(species.commonName);
  });

  it('falls back to the common name when no nickname is given', () => {
    expect(buildPlant({ ...base, nickname: '   ' }).nickname).toBe(species.commonName);
  });

  it('trims free text', () => {
    const plant = buildPlant({ ...base, nickname: 'Moss' });

    expect(plant.locationName).toBe('Shelf');
    expect(plant.notes).toBe('Note');
  });

  it('starts with no care history', () => {
    expect(buildPlant({ ...base, nickname: 'Moss' }).careEvents).toEqual([]);
  });
});

describe('buildWateringEvent', () => {
  it('records an amount together with its unit', () => {
    const event = buildWateringEvent({ amount: 250, waterUnit: 'mL' });

    expect(event.amount).toBe(250);
    expect(event.waterUnit).toBe('mL');
  });

  it('drops the unit when no amount was entered, since it would mean nothing', () => {
    const event = buildWateringEvent({ waterUnit: 'mL' });

    expect(event.amount).toBeUndefined();
    expect(event.waterUnit).toBeUndefined();
  });

  it('trims the note and defaults it to empty', () => {
    expect(buildWateringEvent({ note: '  Dry  ' }).note).toBe('Dry');
    expect(buildWateringEvent().note).toBe('');
  });

  it('accepts a backdated timestamp', () => {
    expect(buildWateringEvent({ timestamp: '2026-03-01T09:00:00.000Z' }).timestamp).toBe('2026-03-01T09:00:00.000Z');
  });
});

describe('persistedSlice', () => {
  it('writes the schema version and drops the hydration flag', () => {
    const slice = persistedSlice(hydrated());

    expect(slice.version).toBe(CURRENT_SCHEMA_VERSION);
    expect('hydrated' in slice).toBe(false);
  });
});
