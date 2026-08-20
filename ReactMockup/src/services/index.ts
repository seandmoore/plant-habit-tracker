import { bundledCatalogService } from './catalogService';
import { scriptedCompanionService } from './companionService';
import { demoIdentificationService } from './identificationService';
import type { Services } from './types';

/** The preview's composition root. One place to swap a demo service for a live one. */
export const services: Services = {
  catalog: bundledCatalogService,
  identification: demoIdentificationService,
  companion: scriptedCompanionService,
};

export * from './types';
export { bundledCatalogService, demoIdentificationService, scriptedCompanionService };
export { welcomeMessage } from './companionService';
