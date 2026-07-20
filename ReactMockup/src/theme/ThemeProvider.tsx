import React, { createContext, PropsWithChildren, useContext, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { usePlantStore } from '@/store/PlantStore';
import { PlantTheme, resolveTheme } from './theme';

const ThemeContext = createContext<PlantTheme | null>(null);

export function ThemeProvider({ children }: PropsWithChildren) {
  const system = useColorScheme();
  const { state } = usePlantStore();
  const theme = useMemo(() => resolveTheme(state.colorMode, system), [state.colorMode, system]);
  return <ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>;
}

export const usePlantTheme = (): PlantTheme => {
  const theme = useContext(ThemeContext);
  if (!theme) throw new Error('usePlantTheme must be used inside ThemeProvider');
  return theme;
};
