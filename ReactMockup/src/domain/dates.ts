export const MILLISECONDS_PER_DAY = 86_400_000;

export const startOfDay = (date: Date): Date =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate());

export const addDays = (date: Date, days: number): Date => {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

/** Whole calendar days between two instants, ignoring the time of day on either side. */
export const dayDifference = (from: Date, to: Date): number =>
  Math.round((startOfDay(to).getTime() - startOfDay(from).getTime()) / MILLISECONDS_PER_DAY);

export const daysAgo = (days: number, now = new Date()): Date => addDays(now, -days);
