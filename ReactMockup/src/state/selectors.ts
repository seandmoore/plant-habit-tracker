import { useMemo } from 'react';
import { careQueue, findPlant, wateringsSince } from '@/domain/selectors';
import type { CareQueueEntry, UserPlant } from '@/domain/types';
import { usePlantStore } from './PlantStore';

export function useCareQueue(): CareQueueEntry[] {
  const { state } = usePlantStore();
  return useMemo(() => careQueue(state.plants), [state.plants]);
}

export function useWateringsThisWeek(): number {
  const { state } = usePlantStore();
  return useMemo(() => wateringsSince(state.plants, 7), [state.plants]);
}

export function usePlant(id: string | undefined): UserPlant | undefined {
  const { state } = usePlantStore();
  return useMemo(() => findPlant(state.plants, id), [id, state.plants]);
}
