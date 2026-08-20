import { findSpecies, starterCatalog } from '@/data/catalog';
import { filterSpecies } from '@/domain/selectors';
import type { CatalogService } from './types';

const delay = (milliseconds: number) => new Promise((resolve) => setTimeout(resolve, milliseconds));

/**
 * Backed by the bundled catalog, but asynchronous on purpose: screens go through this
 * interface rather than importing the array, so swapping in the Worker's /v1/plants endpoint
 * is a change here alone.
 */
export const bundledCatalogService: CatalogService = {
  async search(query) {
    return filterSpecies(starterCatalog, query);
  },

  async species(id) {
    await delay(0);
    return findSpecies(id);
  },
};
