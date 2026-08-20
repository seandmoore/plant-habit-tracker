import { bundledCatalogService, demoIdentificationService, scriptedCompanionService } from './index';

describe('bundledCatalogService', () => {
  it('searches common and scientific names', async () => {
    await expect(bundledCatalogService.search('monstera')).resolves.toEqual(
      expect.arrayContaining([expect.objectContaining({ id: 'monstera-deliciosa' })]),
    );
    await expect(bundledCatalogService.search('ocimum')).resolves.toEqual(
      expect.arrayContaining([expect.objectContaining({ id: 'ocimum-basilicum' })]),
    );
  });

  it('returns the whole catalog for an empty query', async () => {
    await expect(bundledCatalogService.search('')).resolves.toHaveLength(10);
  });

  it('returns nothing for a query that matches nothing', async () => {
    await expect(bundledCatalogService.search('zzzznope')).resolves.toEqual([]);
  });

  it('looks a species up by id', async () => {
    await expect(bundledCatalogService.species('ficus-lyrata')).resolves.toEqual(
      expect.objectContaining({ scientificName: 'Ficus lyrata' }),
    );
    await expect(bundledCatalogService.species('nope')).resolves.toBeUndefined();
  });
});

describe('demoIdentificationService', () => {
  it('returns species candidates with binomial names', async () => {
    const results = await demoIdentificationService.identify('local-photo', 'species');

    expect(results.every((result) => result.scientificName)).toBe(true);
  });

  it('returns health candidates without a binomial name', async () => {
    const results = await demoIdentificationService.identify('local-photo', 'health');

    expect(results.every((result) => result.scientificName === undefined)).toBe(true);
  });

  it('combines both kinds for a both-mode scan', async () => {
    const results = await demoIdentificationService.identify('local-photo', 'both');

    expect(results.some((result) => result.scientificName)).toBe(true);
    expect(results.some((result) => result.title.includes('stress'))).toBe(true);
  });

  it('keeps every confidence inside the contract range', async () => {
    const results = await demoIdentificationService.identify('local-photo', 'both');

    expect(results.every((result) => result.confidence >= 0 && result.confidence <= 1)).toBe(true);
  });

  it('labels every suggestion as a demo result', async () => {
    const results = await demoIdentificationService.identify('local-photo', 'both');

    expect(results.every((result) => result.source.toLowerCase().includes('demo'))).toBe(true);
  });
});

describe('scriptedCompanionService', () => {
  it('never phrases a health answer as a diagnosis', async () => {
    await expect(scriptedCompanionService.respond('Why are the leaves yellow?', [])).resolves.toMatch(/not a diagnosis/i);
  });

  it('treats a care date as a reminder rather than a command', async () => {
    await expect(scriptedCompanionService.respond('Should I water it?', [])).resolves.toMatch(/reminder, not a command/i);
  });

  it('repeats the facts it was given instead of inventing any', async () => {
    const response = await scriptedCompanionService.respond('Tell me about it', ['Moss is a Monstera.']);

    expect(response).toContain('Moss is a Monstera.');
  });

  it('offers what it can do when it has no facts and no matching topic', async () => {
    await expect(scriptedCompanionService.respond('Hello', [])).resolves.toMatch(/I can help you add a plant/);
  });
});
