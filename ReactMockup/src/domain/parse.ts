/** Accepts both decimal separators, and treats anything unparseable as "not recorded". */
export function parseAmount(input: string): number | undefined {
  const parsed = Number.parseFloat(input.trim().replace(',', '.'));
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}
