import { useEffect, useMemo, useState } from 'react';
import { AppState } from 'react-native';
import { careQueue, findPlant, wateringsSince } from '@/domain/selectors';
import type { CareQueueEntry, UserPlant } from '@/domain/types';
import { usePlantStore } from './PlantStore';

/** Refresh rolling windows while open and immediately after returning from the background. */
function useNow(): Date {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const refresh = () => setNow(new Date());
    const timer = setInterval(refresh, 1000);
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active') refresh();
    });
    return () => { clearInterval(timer); subscription.remove(); };
  }, []);
  return now;
}

export function useCareQueue(): CareQueueEntry[] {
  const { state } = usePlantStore();
  const now = useNow();
  return useMemo(() => careQueue(state.plants, now), [state.plants, now]);
}

export function useWateringsThisWeek(): number {
  const { state } = usePlantStore();
  const now = useNow();
  return useMemo(() => wateringsSince(state.plants, 7, now), [state.plants, now]);
}

export function usePlant(id: string | undefined): UserPlant | undefined {
  const { state } = usePlantStore();
  return useMemo(() => findPlant(state.plants, id), [id, state.plants]);
}
