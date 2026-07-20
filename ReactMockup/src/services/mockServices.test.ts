import { mockCatalogService, mockCompanionService, mockIdentificationService } from './mockServices';

describe('mock services', () => {
  it('searches common and scientific names', async () => {
    await expect(mockCatalogService.search('monstera')).resolves.toEqual(expect.arrayContaining([expect.objectContaining({ id: 'monstera-deliciosa' })]));
    await expect(mockCatalogService.search('ocimum')).resolves.toEqual(expect.arrayContaining([expect.objectContaining({ id: 'ocimum-basilicum' })]));
  });

  it('returns both species and health suggestions', async () => {
    const results = await mockIdentificationService.identify('local-photo', 'both');
    expect(results.some((result) => result.scientificName)).toBe(true);
    expect(results.some((result) => result.title.includes('stress'))).toBe(true);
  });

  it('does not phrase a scripted health answer as a diagnosis', async () => {
    const response = await mockCompanionService.respond('Why are the leaves yellow?', []);
    expect(response).toMatch(/not a diagnosis/i);
  });
});
