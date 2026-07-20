import { createSampleState } from '@/data/sampleState';
import { initialState, plantReducer } from './PlantStore';

describe('plantReducer', () => {
  it('adds a watering event without changing another plant', () => {
    const state = { ...createSampleState(), hydrated: true };
    const first = state.plants[0]!;
    const second = state.plants[1]!;
    const next = plantReducer(state, {
      type: 'addCareEvent', plantId: first.id,
      event: { id: 'new-water', kind: 'watered', timestamp: '2026-07-18T09:00:00.000Z', amount: 200, waterUnit: 'mL', note: '' },
    });
    expect(next.plants.find((plant) => plant.id === first.id)?.careEvents[0]?.id).toBe('new-water');
    expect(next.plants.find((plant) => plant.id === second.id)?.careEvents).toEqual(second.careEvents);
  });

  it('clears plants while keeping onboarding complete', () => {
    const next = plantReducer({ ...createSampleState(), hydrated: true }, { type: 'clearAll' });
    expect(next.plants).toEqual([]);
    expect(next.hasCompletedOnboarding).toBe(true);
  });

  it('restores fresh sample data', () => {
    const cleared = { ...initialState(), hydrated: true, plants: [] };
    const restored = plantReducer(cleared, { type: 'resetSamples' });
    expect(restored.plants.length).toBeGreaterThanOrEqual(3);
    expect(restored.hydrated).toBe(true);
  });
});
