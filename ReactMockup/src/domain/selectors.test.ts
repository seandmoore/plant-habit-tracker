import { careHistory, careQueue, filterPlants, filterSpecies, findPlant, groundingFacts, needsAttention, wateringsSince } from './selectors';
import { starterCatalog } from '@/data/catalog';
import type { CareEvent, UserPlant } from './types';

const plant = (id: string, overrides: Partial<UserPlant> = {}): UserPlant => ({
  id,
  nickname: id,
  speciesId: 'monstera-deliciosa',
  commonName: 'Monstera',
  scientificName: 'Monstera deliciosa',
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

const watered = (id: string, timestamp: string): CareEvent => ({ id, kind: 'watered', timestamp, note: '' });

describe('careQueue', () => {
  const now = new Date(2026, 2, 20);

  it('puts overdue plants first, then due today, then upcoming', () => {
    const queue = careQueue([
      plant('upcoming', { careEvents: [watered('a', '2026-03-19T09:00:00.000Z')] }),
      plant('overdue', { careEvents: [watered('b', '2026-03-01T09:00:00.000Z')] }),
      plant('dueToday', { careEvents: [watered('c', '2026-03-10T09:00:00.000Z')] }),
    ], now);

    expect(queue.map((entry) => entry.plant.id)).toEqual(['overdue', 'dueToday', 'upcoming']);
  });

  it('breaks ties within a status by due date', () => {
    const queue = careQueue([
      plant('later', { careEvents: [watered('a', '2026-03-05T09:00:00.000Z')] }),
      plant('sooner', { careEvents: [watered('b', '2026-03-01T09:00:00.000Z')] }),
    ], now);

    expect(queue.map((entry) => entry.plant.id)).toEqual(['sooner', 'later']);
  });

  it('marks only overdue and due-today plants as needing attention', () => {
    const queue = careQueue([
      plant('overdue', { careEvents: [watered('a', '2026-03-01T09:00:00.000Z')] }),
      plant('upcoming', { careEvents: [watered('b', '2026-03-19T09:00:00.000Z')] }),
    ], now);

    expect(queue.map(needsAttention)).toEqual([true, false]);
  });

  it('returns an empty queue for an empty collection', () => {
    expect(careQueue([], now)).toEqual([]);
  });
});

describe('wateringsSince', () => {
  const now = new Date('2026-03-20T12:00:00.000Z');

  it('counts waterings across every plant inside the window', () => {
    const plants = [
      plant('a', { careEvents: [watered('1', '2026-03-18T09:00:00.000Z'), watered('2', '2026-03-19T09:00:00.000Z')] }),
      plant('b', { careEvents: [watered('3', '2026-03-17T09:00:00.000Z')] }),
    ];

    expect(wateringsSince(plants, 7, now)).toBe(3);
  });

  it('excludes waterings older than the window', () => {
    const plants = [plant('a', { careEvents: [watered('1', '2026-03-01T09:00:00.000Z')] })];

    expect(wateringsSince(plants, 7, now)).toBe(0);
  });

  it('ignores care events that are not waterings', () => {
    const plants = [plant('a', { careEvents: [{ id: '1', kind: 'pruned', timestamp: '2026-03-19T09:00:00.000Z', note: '' }] })];

    expect(wateringsSince(plants, 7, now)).toBe(0);
  });
});

describe('filtering', () => {
  const plants = [
    plant('moss', { nickname: 'Moss' }),
    plant('sunny', { nickname: 'Sunny', commonName: 'Basil', scientificName: 'Ocimum basilicum' }),
  ];

  it('matches a nickname, common name, or scientific name', () => {
    expect(filterPlants(plants, 'moss').map((entry) => entry.id)).toEqual(['moss']);
    expect(filterPlants(plants, 'basil').map((entry) => entry.id)).toEqual(['sunny']);
    expect(filterPlants(plants, 'ocimum').map((entry) => entry.id)).toEqual(['sunny']);
  });

  it('ignores case and surrounding whitespace', () => {
    expect(filterPlants(plants, '  MOSS ').map((entry) => entry.id)).toEqual(['moss']);
  });

  it('returns everything for an empty query', () => {
    expect(filterPlants(plants, '   ')).toHaveLength(2);
    expect(filterSpecies(starterCatalog, '')).toHaveLength(starterCatalog.length);
  });

  it('searches the catalog by both names', () => {
    expect(filterSpecies(starterCatalog, 'snake')[0]?.id).toBe('sansevieria-trifasciata');
    expect(filterSpecies(starterCatalog, 'lavandula')[0]?.id).toBe('lavandula-angustifolia');
  });

  it('finds a plant by id and tolerates a missing id', () => {
    expect(findPlant(plants, 'moss')?.nickname).toBe('Moss');
    expect(findPlant(plants, undefined)).toBeUndefined();
    expect(findPlant(plants, 'nope')).toBeUndefined();
  });
});

describe('careHistory', () => {
  it('orders events newest first without mutating the plant', () => {
    const source = plant('a', {
      careEvents: [watered('old', '2026-03-01T09:00:00.000Z'), watered('new', '2026-03-19T09:00:00.000Z')],
    });

    expect(careHistory(source).map((event) => event.id)).toEqual(['new', 'old']);
    expect(source.careEvents.map((event) => event.id)).toEqual(['old', 'new']);
  });
});

describe('groundingFacts', () => {
  it('returns nothing when no plant is selected', () => {
    expect(groundingFacts(undefined, 'Indoor', 'Medium light')).toEqual([]);
  });

  it('describes only what the app has recorded', () => {
    const facts = groundingFacts(
      plant('moss', { nickname: 'Moss', careEvents: [watered('1', '2026-03-18T09:00:00.000Z')] }),
      'Indoor',
      'Medium light',
      new Date(2026, 2, 20),
    );

    expect(facts[0]).toBe('Moss is recorded as Monstera (Monstera deliciosa).');
    expect(facts[1]).toBe('It is indoor in medium light.');
    expect(facts[2]).toContain('Feel the soil before watering.');
    expect(facts[3]).toContain('The latest watering log is dated');
  });

  it('omits the watering fact when nothing has been logged', () => {
    const facts = groundingFacts(plant('moss'), 'Indoor', 'Medium light', new Date(2026, 2, 20));

    expect(facts).toHaveLength(3);
  });
});
