import type { LightLevel, PlantEnvironment } from './types';

/**
 * Mirrors Contract/care-rules.json. `src/domain/contract.test.ts` fails if the two diverge,
 * so a rule change has to land here and in the other implementations together.
 *
 * Expressing the rules as a table rather than a chain of if statements is what lets the
 * planner build the interval and the human explanation in a single pass — the app can always
 * say which factors moved a date, because the phrase travels with the number that moved it.
 */
export interface Modifier<Key extends string> {
  key: Key;
  days: number;
  factor: string | null;
}

export interface SeasonModifier extends Modifier<string> {
  months: number[];
  excludesEnvironments: PlantEnvironment[];
}

export const careRulesVersion = 1;

export const bounds = { minimumIntervalDays: 1, maximumIntervalDays: 45 } as const;

export const environmentModifiers: Modifier<PlantEnvironment>[] = [
  { key: 'indoor', days: 0, factor: 'kept indoors' },
  { key: 'outdoorContainer', days: -2, factor: 'an outdoor pot can dry faster' },
  { key: 'outdoorGround', days: 1, factor: 'garden soil holds moisture longer than many pots' },
];

export const lightModifiers: Modifier<LightLevel>[] = [
  { key: 'low', days: 2, factor: 'lower light usually slows water use' },
  { key: 'medium', days: 0, factor: null },
  { key: 'brightIndirect', days: -1, factor: 'bright light can increase water use' },
  { key: 'direct', days: -2, factor: 'direct sun can dry soil faster' },
];

/** Ordered by precedence: at most one season modifier applies, and the warm window wins. */
export const seasonModifiers: SeasonModifier[] = [
  {
    key: 'warmOutdoor',
    months: [6, 7, 8],
    days: -2,
    factor: 'it is the warmer part of the year',
    excludesEnvironments: ['indoor'],
  },
  {
    key: 'cool',
    months: [11, 12, 1, 2],
    days: 2,
    factor: 'plants often use less water in cooler months',
    excludesEnvironments: [],
  },
];

export const phrasing = {
  overdueTitle: 'Check soil now',
  dueTodayTitle: 'Check soil today',
  upcomingTitleTemplate: 'Check soil in {days} day{plural}',
  explanationWithoutFactors: 'Based on this species’ starting care interval.',
  explanationTemplate: 'Based on its starting interval and the fact that it is {factors}.',
  reasonSuffix: 'Feel the soil before watering.',
} as const;
