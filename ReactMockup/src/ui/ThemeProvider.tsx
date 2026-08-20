import React, { createContext, useContext, useMemo } from 'react';
import type { PropsWithChildren } from 'react';
import { useColorScheme } from 'react-native';
import { usePlantStore } from '@/state/PlantStore';
import { lightTheme, resolveTheme } from './theme';
import type { Theme } from './theme';

const ThemeContext = createContext<Theme>(lightTheme);

export function ThemeProvider({ children }: PropsWithChildren) {
  const system = useColorScheme();
  const { state } = usePlantStore();
  const theme = useMemo(() => resolveTheme(state.colorMode, system), [state.colorMode, system]);

  return <ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>;
}

export const useTheme = (): Theme => useContext(ThemeContext);
