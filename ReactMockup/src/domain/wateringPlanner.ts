import { bounds, environmentModifiers, lightModifiers, phrasing, seasonModifiers } from './careRules';
import { addDays, dayDifference } from './dates';
import type {
  CareRecommendation,
  LightLevel,
  PlantEnvironment,
  RecommendationStatus,
  UserPlant,
} from './types';

/**
 * Everything the planner needs, and nothing about how a plant is stored. Keeping this
 * separate from UserPlant is what lets the golden contract vectors exercise the planner
 * without inventing a whole persisted plant for each case.
 */
export interface CareProfile {
  baselineWateringDays: number;
  environment: PlantEnvironment;
  light: LightLevel;
  anchor: Date;
}

interface AppliedInterval {
  days: number;
  factors: string[];
}

export const latestWateringDate = (plant: UserPlant): Date | undefined => {
  const timestamps = plant.careEvents
    .filter((event) => event.kind === 'watered')
    .map((event) => new Date(event.timestamp).getTime());
  return timestamps.length > 0 ? new Date(Math.max(...timestamps)) : undefined;
};

/** A plant's schedule is anchored to its last watering, or to the day it was added. */
export const careProfileFor = (plant: UserPlant): CareProfile => ({
  baselineWateringDays: plant.baselineWateringDays,
  environment: plant.environment,
  light: plant.light,
  anchor: latestWateringDate(plant) ?? new Date(plant.dateAdded),
});

export function resolveInterval(profile: CareProfile, now: Date): AppliedInterval {
  const month = now.getMonth() + 1;
  const applied = [
    environmentModifiers.find((entry) => entry.key === profile.environment),
    lightModifiers.find((entry) => entry.key === profile.light),
    // seasonModifiers is ordered by precedence, so the first match is the only one that applies.
    seasonModifiers.find((entry) =>
      entry.months.includes(month) && !entry.excludesEnvironments.includes(profile.environment)),
  ];

  let days = Math.max(1, profile.baselineWateringDays);
  const factors: string[] = [];

  for (const modifier of applied) {
    if (!modifier) continue;
    days += modifier.days;
    if (modifier.factor) factors.push(modifier.factor);
  }

  return {
    days: Math.min(Math.max(days, bounds.minimumIntervalDays), bounds.maximumIntervalDays),
    factors,
  };
}

export function wateringRecommendation(plant: UserPlant, now = new Date()): CareRecommendation {
  return { plantId: plant.id, ...planCare(careProfileFor(plant), now) };
}

export function planCare(profile: CareProfile, now = new Date()): Omit<CareRecommendation, 'plantId'> {
  const { days, factors } = resolveInterval(profile, now);
  const dueDate = addDays(profile.anchor, days);
  const difference = dayDifference(now, dueDate);

  return {
    dueDate: dueDate.toISOString(),
    intervalDays: days,
    status: statusFor(difference),
    title: titleFor(difference),
    reason: `${explanationFor(factors)} ${phrasing.reasonSuffix}`,
  };
}

const statusFor = (difference: number): RecommendationStatus =>
  difference < 0 ? 'overdue' : difference === 0 ? 'dueToday' : 'upcoming';

const titleFor = (difference: number): string => {
  if (difference < 0) return phrasing.overdueTitle;
  if (difference === 0) return phrasing.dueTodayTitle;
  return phrasing.upcomingTitleTemplate
    .replace('{days}', String(difference))
    .replace('{plural}', difference === 1 ? '' : 's');
};

const explanationFor = (factors: string[]): string =>
  factors.length === 0
    ? phrasing.explanationWithoutFactors
    : phrasing.explanationTemplate.replace('{factors}', factors.join(', '));
