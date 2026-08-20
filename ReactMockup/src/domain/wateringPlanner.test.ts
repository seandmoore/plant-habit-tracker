import { careProfileFor, latestWateringDate, planCare, resolveInterval, wateringRecommendation } from './wateringPlanner';
import type { CareProfile } from './wateringPlanner';
import type { UserPlant } from './types';

const makePlant = (overrides: Partial<UserPlant> = {}): UserPlant => ({
  id: 'test',
  nickname: 'Test',
  speciesId: 'test',
  commonName: 'Test plant',
  scientificName: 'Planta testii',
  environment: 'indoor',
  light: 'medium',
  locationName: '',
  dateAdded: '2026-03-01T09:00:00.000Z',
  baselineWateringDays: 10,
  reminderEnabled: false,
  reminderHour: 9,
  notes: '',
  careEvents: [],
  ...overrides,
});

const profile = (overrides: Partial<CareProfile> = {}): CareProfile => ({
  baselineWateringDays: 10,
  environment: 'indoor',
  light: 'medium',
  anchor: new Date(2026, 2, 1),
  ...overrides,
});

describe('resolveInterval', () => {
  it('collects one factor phrase for every modifier that moved the number', () => {
    const { days, factors } = resolveInterval(
      profile({ environment: 'outdoorContainer', light: 'direct' }),
      new Date(2026, 6, 10),
    );

    expect(days).toBe(4);
    expect(factors).toEqual([
      'an outdoor pot can dry faster',
      'direct sun can dry soil faster',
      'it is the warmer part of the year',
    ]);
  });

  it('contributes no phrase for a light level that changes nothing', () => {
    const { factors } = resolveInterval(profile(), new Date(2026, 2, 1));

    expect(factors).toEqual(['kept indoors']);
  });

  it('never applies the warm season modifier to an indoor plant', () => {
    const indoors = resolveInterval(profile({ light: 'direct' }), new Date(2026, 6, 15));

    expect(indoors.days).toBe(8);
    expect(indoors.factors).not.toContain('it is the warmer part of the year');
  });

  it('applies at most one season modifier', () => {
    const { factors } = resolveInterval(profile({ environment: 'outdoorContainer' }), new Date(2026, 5, 20));

    expect(factors.filter((factor) => factor.includes('year') || factor.includes('cooler'))).toHaveLength(1);
  });

  it('clamps to the contract bounds in both directions', () => {
    expect(resolveInterval(profile({ baselineWateringDays: 1, environment: 'outdoorContainer', light: 'direct' }), new Date(2026, 6, 1)).days).toBe(1);
    expect(resolveInterval(profile({ baselineWateringDays: 45, environment: 'outdoorGround', light: 'low' }), new Date(2026, 11, 1)).days).toBe(45);
  });

  it('treats a nonsensical baseline as the minimum before modifiers', () => {
    expect(resolveInterval(profile({ baselineWateringDays: 0 }), new Date(2026, 2, 1)).days).toBe(1);
  });
});

describe('planCare', () => {
  it('always tells people to check the soil themselves', () => {
    expect(planCare(profile(), new Date(2026, 2, 1)).reason).toContain('Feel the soil before watering.');
  });

  it('reports overdue when the due date has passed', () => {
    const result = planCare(profile({ anchor: new Date(2026, 2, 1) }), new Date(2026, 2, 20));

    expect(result.status).toBe('overdue');
    expect(result.title).toBe('Check soil now');
  });

  it('reports due today when the due date is today', () => {
    const result = planCare(profile({ anchor: new Date(2026, 2, 10) }), new Date(2026, 2, 20));

    expect(result.status).toBe('dueToday');
    expect(result.title).toBe('Check soil today');
  });

  it('uses the singular day phrase exactly one day out', () => {
    expect(planCare(profile({ anchor: new Date(2026, 2, 11) }), new Date(2026, 2, 20)).title)
      .toBe('Check soil in 1 day');
  });

  it('uses the plural day phrase beyond one day', () => {
    expect(planCare(profile({ anchor: new Date(2026, 2, 12) }), new Date(2026, 2, 20)).title)
      .toBe('Check soil in 2 days');
  });
});

describe('careProfileFor', () => {
  it('anchors to the date added when nothing has been watered', () => {
    expect(careProfileFor(makePlant()).anchor).toEqual(new Date('2026-03-01T09:00:00.000Z'));
  });

  it('anchors to the most recent watering, whatever order events are stored in', () => {
    const plant = makePlant({
      careEvents: [
        { id: 'a', kind: 'watered', timestamp: '2026-03-08T09:00:00.000Z', note: '' },
        { id: 'b', kind: 'watered', timestamp: '2026-03-14T09:00:00.000Z', note: '' },
        { id: 'c', kind: 'watered', timestamp: '2026-03-02T09:00:00.000Z', note: '' },
      ],
    });

    expect(careProfileFor(plant).anchor).toEqual(new Date('2026-03-14T09:00:00.000Z'));
  });

  it('ignores care events that are not waterings', () => {
    const plant = makePlant({
      careEvents: [{ id: 'a', kind: 'pruned', timestamp: '2026-03-20T09:00:00.000Z', note: '' }],
    });

    expect(latestWateringDate(plant)).toBeUndefined();
    expect(careProfileFor(plant).anchor).toEqual(new Date('2026-03-01T09:00:00.000Z'));
  });
});

describe('wateringRecommendation', () => {
  it('carries the plant id through to the recommendation', () => {
    expect(wateringRecommendation(makePlant({ id: 'moss' }), new Date(2026, 2, 1)).plantId).toBe('moss');
  });
});
