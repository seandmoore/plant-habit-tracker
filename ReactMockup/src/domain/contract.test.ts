import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { starterCatalog, catalogVersion } from '@/data/catalog';
import {
  bounds,
  careRulesVersion,
  environmentModifiers,
  lightModifiers,
  phrasing,
  seasonModifiers,
} from './careRules';
import { planCare } from './wateringPlanner';
import type { CareProfile } from './wateringPlanner';
import type { LightLevel, PlantEnvironment } from './types';

const contract = <T>(name: string): T =>
  JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'Contract', name), 'utf8')) as T;

interface VectorDocument {
  vectors: {
    name: string;
    input: {
      baselineWateringDays: number;
      environment: PlantEnvironment;
      light: LightLevel;
      anchorDate: string;
      asOfDate: string;
    };
    expected: { intervalDays: number; dueDate: string; status: string; title: string; reason: string };
  }[];
}

/** Vectors carry local calendar dates so they stay timezone independent across implementations. */
const localDate = (value: string): Date => {
  const [year, month, day] = value.split('-').map(Number) as [number, number, number];
  return new Date(year, month - 1, day);
};

const localDateString = (value: Date): string =>
  `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, '0')}-${String(value.getDate()).padStart(2, '0')}`;

describe('golden recommendation vectors', () => {
  const { vectors } = contract<VectorDocument>('recommendation-vectors.json');

  it('covers every environment, light level, and season branch', () => {
    expect(vectors.length).toBeGreaterThanOrEqual(13);
  });

  it.each(vectors.map((vector) => [vector.name, vector] as const))('%s', (_name, vector) => {
    const profile: CareProfile = {
      baselineWateringDays: vector.input.baselineWateringDays,
      environment: vector.input.environment,
      light: vector.input.light,
      anchor: localDate(vector.input.anchorDate),
    };

    const result = planCare(profile, localDate(vector.input.asOfDate));

    expect(result.intervalDays).toBe(vector.expected.intervalDays);
    expect(result.status).toBe(vector.expected.status);
    expect(result.title).toBe(vector.expected.title);
    expect(result.reason).toBe(vector.expected.reason);
    expect(localDateString(new Date(result.dueDate))).toBe(vector.expected.dueDate);
  });
});

describe('care rules parity', () => {
  const rules = contract<{
    version: number;
    bounds: { minimumIntervalDays: number; maximumIntervalDays: number };
    environmentModifiers: unknown[];
    lightModifiers: unknown[];
    seasonModifiers: unknown[];
    seasonPrecedence: string[];
    phrasing: Record<string, string>;
  }>('care-rules.json');

  it('matches the contract version and bounds', () => {
    expect(careRulesVersion).toBe(rules.version);
    expect(bounds).toEqual(rules.bounds);
  });

  it('matches the environment and light modifier tables', () => {
    expect(environmentModifiers).toEqual(rules.environmentModifiers);
    expect(lightModifiers).toEqual(rules.lightModifiers);
  });

  it('matches the season modifiers and keeps them in precedence order', () => {
    expect(seasonModifiers).toEqual(rules.seasonModifiers);
    expect(seasonModifiers.map((entry) => entry.key)).toEqual(rules.seasonPrecedence);
  });

  it('words every recommendation exactly as the contract specifies', () => {
    expect({ ...phrasing }).toEqual(rules.phrasing);
  });
});

describe('catalog parity', () => {
  const catalog = contract<{ version: number; species: Record<string, unknown>[] }>('catalog.json');

  it('matches the contract version', () => {
    expect(catalogVersion).toBe(catalog.version);
  });

  it('carries every contract species, in order, with the same care values', () => {
    expect(starterCatalog.map((species) => species.id)).toEqual(catalog.species.map((species) => species.id));

    for (const [index, species] of starterCatalog.entries()) {
      const source = catalog.species[index]!;
      expect(species).toEqual({
        id: source.id,
        commonName: source.commonName,
        scientificName: source.scientificName,
        summary: source.summary,
        baselineWateringDays: source.baselineWateringDays,
        light: source.light,
        soil: source.soil,
        humidity: source.humidity,
        environments: source.environments,
        icon: source.icon,
        // The Expo app renders MaterialCommunityIcons, so symbolName is deliberately dropped.
        ...(source.toxicityNote ? { toxicityNote: source.toxicityNote } : {}),
      });
    }
  });

  it('keeps every baseline interval inside the planner bounds', () => {
    for (const species of starterCatalog) {
      expect(species.baselineWateringDays).toBeGreaterThanOrEqual(bounds.minimumIntervalDays);
      expect(species.baselineWateringDays).toBeLessThanOrEqual(bounds.maximumIntervalDays);
    }
  });
});
