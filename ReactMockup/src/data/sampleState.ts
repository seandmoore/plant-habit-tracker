import { PersistedPlantState, UserPlant } from '@/domain/types';

const relativeDate = (daysAgo: number, hour = 9): string => {
  const date = new Date();
  date.setHours(hour, 0, 0, 0);
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString();
};

export const createSamplePlants = (): UserPlant[] => [
  {
    id: 'sample-moss', nickname: 'Moss', speciesId: 'monstera-deliciosa', commonName: 'Monstera',
    scientificName: 'Monstera deliciosa', environment: 'indoor', light: 'brightIndirect', locationName: 'Living room',
    dateAdded: relativeDate(64), baselineWateringDays: 9, reminderEnabled: true, reminderHour: 9,
    notes: 'New leaf unfurled recently.',
    careEvents: [
      { id: 'event-moss-1', kind: 'watered', timestamp: relativeDate(10), amount: 420, waterUnit: 'mL', note: 'Top layer was dry.' },
      { id: 'event-moss-2', kind: 'healthNote', timestamp: relativeDate(4), note: 'Rotated toward the window.' },
    ],
  },
  {
    id: 'sample-sunny', nickname: 'Sunny', speciesId: 'ocimum-basilicum', commonName: 'Basil',
    scientificName: 'Ocimum basilicum', environment: 'outdoorContainer', light: 'direct', locationName: 'Kitchen patio',
    dateAdded: relativeDate(26), baselineWateringDays: 3, reminderEnabled: false, reminderHour: 8,
    notes: 'Pinch flowers to encourage leaves.',
    careEvents: [
      { id: 'event-sunny-1', kind: 'watered', timestamp: relativeDate(2), amount: 12, waterUnit: 'fl oz', note: '' },
      { id: 'event-sunny-2', kind: 'pruned', timestamp: relativeDate(6), note: 'Harvested the tallest stems.' },
    ],
  },
  {
    id: 'sample-sage', nickname: 'Sage', speciesId: 'sansevieria-trifasciata', commonName: 'Snake plant',
    scientificName: 'Dracaena trifasciata', environment: 'indoor', light: 'low', locationName: 'Office',
    dateAdded: relativeDate(120), baselineWateringDays: 18, reminderEnabled: true, reminderHour: 10,
    notes: 'Use extra caution not to overwater.',
    careEvents: [{ id: 'event-sage-1', kind: 'watered', timestamp: relativeDate(14), note: 'Pot felt light.' }],
  },
];

export const createSampleState = (): PersistedPlantState => ({
  version: 1,
  plants: createSamplePlants(),
  hasCompletedOnboarding: true,
  colorMode: 'system',
});
