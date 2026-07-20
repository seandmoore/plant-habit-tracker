import { wateringRecommendation } from './recommendations';
import { UserPlant } from './types';

const makePlant = (overrides: Partial<UserPlant> = {}): UserPlant => ({
  id: 'test', nickname: 'Test', speciesId: 'test', commonName: 'Test plant', scientificName: 'Planta testii',
  environment: 'indoor', light: 'medium', locationName: '', dateAdded: '2026-03-01T09:00:00.000Z',
  baselineWateringDays: 10, reminderEnabled: false, reminderHour: 9, notes: '', careEvents: [], ...overrides,
});

describe('wateringRecommendation', () => {
  it('shortens the interval for an outdoor container in direct summer sun', () => {
    const recommendation = wateringRecommendation(
      makePlant({ environment: 'outdoorContainer', light: 'direct', dateAdded: '2026-07-10T09:00:00.000Z' }),
      new Date('2026-07-10T12:00:00.000Z'),
    );
    expect(recommendation.intervalDays).toBe(4);
    expect(recommendation.status).toBe('upcoming');
  });

  it('lengthens a low-light indoor winter interval', () => {
    const recommendation = wateringRecommendation(
      makePlant({ light: 'low', dateAdded: '2026-12-01T09:00:00.000Z' }),
      new Date('2026-12-01T12:00:00.000Z'),
    );
    expect(recommendation.intervalDays).toBe(14);
    expect(recommendation.reason).toContain('Feel the soil');
  });

  it('anchors the next check to the latest watering', () => {
    const recommendation = wateringRecommendation(
      makePlant({ careEvents: [{ id: 'water', kind: 'watered', timestamp: '2026-03-08T09:00:00.000Z', note: '' }] }),
      new Date('2026-03-20T12:00:00.000Z'),
    );
    expect(recommendation.status).toBe('overdue');
    expect(recommendation.dueDate.startsWith('2026-03-18')).toBe(true);
  });
});
