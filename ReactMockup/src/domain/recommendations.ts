import { CareRecommendation, UserPlant } from './types';

const addDays = (date: Date, days: number): Date => {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

const startOfDay = (date: Date): Date => {
  const result = new Date(date);
  result.setHours(0, 0, 0, 0);
  return result;
};

const dayDifference = (from: Date, to: Date): number =>
  Math.round((startOfDay(to).getTime() - startOfDay(from).getTime()) / 86_400_000);

export const wateringRecommendation = (plant: UserPlant, now = new Date()): CareRecommendation => {
  let interval = Math.max(1, plant.baselineWateringDays);
  const factors: string[] = [];

  if (plant.environment === 'indoor') factors.push('kept indoors');
  if (plant.environment === 'outdoorContainer') {
    interval -= 2;
    factors.push('an outdoor pot can dry faster');
  }
  if (plant.environment === 'outdoorGround') {
    interval += 1;
    factors.push('garden soil holds moisture longer than many pots');
  }

  if (plant.light === 'low') {
    interval += 2;
    factors.push('lower light usually slows water use');
  }
  if (plant.light === 'brightIndirect') {
    interval -= 1;
    factors.push('bright light can increase water use');
  }
  if (plant.light === 'direct') {
    interval -= 2;
    factors.push('direct sun can dry soil faster');
  }

  const month = now.getMonth() + 1;
  if (plant.environment !== 'indoor' && [6, 7, 8].includes(month)) {
    interval -= 2;
    factors.push('it is the warmer part of the year');
  } else if ([11, 12, 1, 2].includes(month)) {
    interval += 2;
    factors.push('plants often use less water in cooler months');
  }

  interval = Math.min(Math.max(interval, 1), 45);
  const latestWatering = plant.careEvents
    .filter((event) => event.kind === 'watered')
    .map((event) => new Date(event.timestamp))
    .sort((a, b) => b.getTime() - a.getTime())[0];
  const anchor = latestWatering ?? new Date(plant.dateAdded);
  const dueDate = addDays(anchor, interval);
  const difference = dayDifference(now, dueDate);
  const status = difference < 0 ? 'overdue' : difference === 0 ? 'dueToday' : 'upcoming';
  const title = difference < 0
    ? 'Check soil now'
    : difference === 0
      ? 'Check soil today'
      : `Check soil in ${difference} day${difference === 1 ? '' : 's'}`;
  const explanation = factors.length === 0
    ? 'Based on this species’ starting care interval.'
    : `Based on its starting interval and the fact that it is ${factors.join(', ')}.`;

  return {
    plantId: plant.id,
    dueDate: dueDate.toISOString(),
    intervalDays: interval,
    status,
    title,
    reason: `${explanation} Feel the soil before watering.`,
  };
};
