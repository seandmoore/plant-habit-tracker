import { MILLISECONDS_PER_DAY } from './dates';
import { wateringRecommendation } from './wateringPlanner';
import type { CareEvent, CareQueueEntry, PlantSpecies, RecommendationStatus, UserPlant } from './types';

const statusRank: Record<RecommendationStatus, number> = { overdue: 0, dueToday: 1, upcoming: 2 };

/**
 * The one place plants are turned into an ordered work list: most urgent first, then by due
 * date. Screens read this instead of sorting inline, so the Today list and the collection
 * cards can never disagree about what is due.
 */
export function careQueue(plants: UserPlant[], now = new Date()): CareQueueEntry[] {
  return plants
    .map((plant) => ({ plant, recommendation: wateringRecommendation(plant, now) }))
    .sort((a, b) =>
      statusRank[a.recommendation.status] - statusRank[b.recommendation.status]
      || a.recommendation.dueDate.localeCompare(b.recommendation.dueDate));
}

export const needsAttention = (entry: CareQueueEntry): boolean =>
  entry.recommendation.status !== 'upcoming';

export function wateringsSince(plants: UserPlant[], days: number, now = new Date()): number {
  const start = now.getTime() - days * MILLISECONDS_PER_DAY;
  return plants
    .flatMap((plant) => plant.careEvents)
    .filter((event) => event.kind === 'watered' && new Date(event.timestamp).getTime() >= start)
    .length;
}

const matches = (query: string, ...fields: string[]): boolean => {
  const normalized = query.trim().toLocaleLowerCase();
  if (!normalized) return true;
  return fields.some((field) => field.toLocaleLowerCase().includes(normalized));
};

export const filterPlants = (plants: UserPlant[], query: string): UserPlant[] =>
  plants.filter((plant) => matches(query, plant.nickname, plant.commonName, plant.scientificName));

export const filterSpecies = (species: PlantSpecies[], query: string): PlantSpecies[] =>
  species.filter((entry) => matches(query, entry.commonName, entry.scientificName));

export const findPlant = (plants: UserPlant[], id: string | undefined): UserPlant | undefined =>
  id ? plants.find((plant) => plant.id === id) : undefined;

/** Newest first, which is the order every history view renders. */
export const careHistory = (plant: UserPlant): CareEvent[] =>
  [...plant.careEvents].sort((a, b) => b.timestamp.localeCompare(a.timestamp));

/**
 * The facts the companion is allowed to use. Building this list here — rather than inside the
 * chat screen — is what keeps the guardrail checkable: the model only ever sees saved records.
 */
export function groundingFacts(
  plant: UserPlant | undefined,
  environmentLabel: string,
  lightLabel: string,
  now = new Date(),
): string[] {
  if (!plant) return [];

  const recommendation = wateringRecommendation(plant, now);
  const facts = [
    `${plant.nickname} is recorded as ${plant.commonName} (${plant.scientificName}).`,
    `It is ${environmentLabel.toLocaleLowerCase()} in ${lightLabel.toLocaleLowerCase()}.`,
    `The next recommendation says: ${recommendation.title}. ${recommendation.reason}`,
  ];

  const watered = plant.careEvents
    .filter((event) => event.kind === 'watered')
    .sort((a, b) => b.timestamp.localeCompare(a.timestamp))[0];
  if (watered) {
    facts.push(`The latest watering log is dated ${new Date(watered.timestamp).toLocaleDateString()}.`);
  }
  return facts;
}
