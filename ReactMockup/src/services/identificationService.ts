import type { ScanCandidate } from '@/domain/types';
import type { IdentificationService } from './types';

const SOURCE = 'Interactive demo result';

const speciesCandidates: ScanCandidate[] = [
  {
    id: 'mock-monstera',
    title: 'Monstera',
    scientificName: 'Monstera deliciosa',
    confidence: 0.86,
    detail: 'Compare leaf shape and growth habit before confirming.',
    source: SOURCE,
  },
  {
    id: 'mock-rhaphidophora',
    title: 'Mini monstera',
    scientificName: 'Rhaphidophora tetrasperma',
    confidence: 0.34,
    detail: 'A visually similar climbing aroid.',
    source: SOURCE,
  },
];

// Deliberately worded as an observation to check, never as a diagnosis.
const healthCandidates: ScanCandidate[] = [
  {
    id: 'mock-stress',
    title: 'Possible watering stress',
    confidence: 0.61,
    detail: 'Check soil moisture, roots, light, and recent care. A photo cannot confirm the cause.',
    source: SOURCE,
  },
];

const delay = (milliseconds: number) => new Promise((resolve) => setTimeout(resolve, milliseconds));

/** Returns fixed suggestions and never uploads the image; the preview stays entirely local. */
export const demoIdentificationService: IdentificationService = {
  async identify(_imageUri, mode) {
    await delay(700);
    if (mode === 'species') return speciesCandidates;
    if (mode === 'health') return healthCandidates;
    return [...speciesCandidates, ...healthCandidates];
  },
};
