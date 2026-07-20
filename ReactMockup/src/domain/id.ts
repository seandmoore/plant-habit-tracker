export const createId = (prefix = 'id'): string => {
  const randomUUID = globalThis.crypto?.randomUUID?.bind(globalThis.crypto);
  return randomUUID ? randomUUID() : `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
};
