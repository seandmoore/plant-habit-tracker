import type { PlantSpecies, ScanCandidate, ScanMode } from '@/domain/types';

export interface CatalogService {
  search(query: string): Promise<PlantSpecies[]>;
  species(id: string): Promise<PlantSpecies | undefined>;
}

export interface IdentificationService {
  identify(imageUri: string, mode: ScanMode): Promise<ScanCandidate[]>;
}

export interface CompanionService {
  respond(question: string, facts: string[]): Promise<string>;
}

export interface Services {
  catalog: CatalogService;
  identification: IdentificationService;
  companion: CompanionService;
}
