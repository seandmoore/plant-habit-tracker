import { act, renderHook } from '@testing-library/react-native';
import { AppState } from 'react-native';
import { createSamplePlants } from '@/data/sampleCollection';
import { useCareQueue, useWateringsThisWeek } from './selectors';

const mockPlants = createSamplePlants();
jest.mock('./PlantStore', () => ({ usePlantStore: () => ({ state: { plants: mockPlants } }) }));

beforeEach(() => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date(2026, 9, 5, 23, 59, 59));
  mockPlants.splice(1);
  Object.assign(mockPlants[0]!, {
    baselineWateringDays: 7, environment: 'indoor', light: 'medium',
    dateAdded: new Date(2026, 8, 29, 12).toISOString(), careEvents: [],
  });
});
afterEach(() => { jest.useRealTimers(); jest.restoreAllMocks(); });

test('care status crosses midnight without changing the plant array', () => {
  const { result, unmount } = renderHook(useCareQueue);
  expect(result.current[0]!.recommendation.status).toBe('upcoming');
  act(() => { jest.advanceTimersByTime(1000); });
  expect(result.current[0]!.recommendation.status).toBe('dueToday');
  unmount();
  expect(jest.getTimerCount()).toBe(0);
});

test('watering ages out of the rolling seven-day window without a plant edit', () => {
  mockPlants[0]!.careEvents = [{ id: 'old', kind: 'watered', note: '', timestamp: new Date(Date.now() - 7 * 86400000).toISOString() }];
  const { result } = renderHook(useWateringsThisWeek);
  expect(result.current).toBe(1);
  act(() => { jest.advanceTimersByTime(1000); });
  expect(result.current).toBe(0);
});

test('foregrounding refreshes immediately even when background timers were suspended', () => {
  const remove = jest.fn();
  let foreground: (state: string) => void = () => {};
  jest.spyOn(AppState, 'addEventListener').mockImplementation((_event, callback) => {
    foreground = callback as typeof foreground;
    return { remove };
  });
  const { result, unmount } = renderHook(useCareQueue);
  act(() => {
    jest.setSystemTime(new Date(2026, 9, 7, 12));
    foreground('active');
  });
  expect(result.current[0]!.recommendation.status).toBe('overdue');
  unmount();
  expect(remove).toHaveBeenCalled();
});
