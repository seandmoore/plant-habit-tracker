import { starterCatalog } from '@/data/catalog';
import { CompanionMessage, ScanCandidate, ScanMode } from '@/domain/types';

export interface CatalogService {
  search(query: string): Promise<typeof starterCatalog>;
}

export interface IdentificationService {
  identify(imageUri: string, mode: ScanMode): Promise<ScanCandidate[]>;
}

export interface CompanionService {
  respond(question: string, facts: string[]): Promise<string>;
}

const wait = (milliseconds: number) => new Promise((resolve) => setTimeout(resolve, milliseconds));

export const mockCatalogService: CatalogService = {
  async search(query) {
    const normalized = query.trim().toLocaleLowerCase();
    if (!normalized) return starterCatalog;
    return starterCatalog.filter((plant) =>
      plant.commonName.toLocaleLowerCase().includes(normalized)
      || plant.scientificName.toLocaleLowerCase().includes(normalized));
  },
};

const speciesCandidates: ScanCandidate[] = [
  { id: 'mock-monstera', title: 'Monstera', scientificName: 'Monstera deliciosa', confidence: 0.86, detail: 'Compare leaf shape and growth habit before confirming.', source: 'Interactive demo result' },
  { id: 'mock-rhaphidophora', title: 'Mini monstera', scientificName: 'Rhaphidophora tetrasperma', confidence: 0.34, detail: 'A visually similar climbing aroid.', source: 'Interactive demo result' },
];
const healthCandidates: ScanCandidate[] = [
  { id: 'mock-stress', title: 'Possible watering stress', confidence: 0.61, detail: 'Check soil moisture, roots, light, and recent care. A photo cannot confirm the cause.', source: 'Interactive demo result' },
];

export const mockIdentificationService: IdentificationService = {
  async identify(_imageUri, mode) {
    await wait(700);
    if (mode === 'species') return speciesCandidates;
    if (mode === 'health') return healthCandidates;
    return [...speciesCandidates, ...healthCandidates];
  },
};

export const mockCompanionService: CompanionService = {
  async respond(question, facts) {
    await wait(350);
    const normalized = question.toLocaleLowerCase();
    const grounding = facts.slice(0, 2).join(' ');
    if (normalized.includes('water') || normalized.includes('dry')) {
      return `Use the care date as a reminder, not a command. Feel the soil first, then water if the root zone is appropriately dry. ${grounding}`.trim();
    }
    if (normalized.includes('yellow') || normalized.includes('brown') || normalized.includes('sick')) {
      return `Leaf changes can have several causes. Check moisture, drainage, light, temperature, and pests. A photo suggestion is not a diagnosis. ${grounding}`.trim();
    }
    if (normalized.includes('light') || normalized.includes('sun')) {
      return `Observe how light moves through the space and change placement gradually. ${grounding}`.trim();
    }
    return grounding || 'I can help you add a plant, understand care checks, log watering, or prepare a clear photo for identification.';
  },
};

export const initialCompanionMessages: CompanionMessage[] = [{
  id: 'companion-welcome',
  role: 'companion',
  text: 'Hi, I’m here to make plant care feel calm and understandable. Ask me about today’s care checks or one of your plants.',
}];
