import type { ColorSchemeName } from 'react-native';
import type { ColorMode } from '@/domain/types';

export interface ThemeColors {
  background: string;
  backgroundEnd: string;
  surface: string;
  surfaceStrong: string;
  border: string;
  text: string;
  secondaryText: string;
  accent: string;
  accentStrong: string;
  onAccent: string;
  mint: string;
  warning: string;
  danger: string;
  chrome: string;
  shadow: string;
}

export interface Theme {
  dark: boolean;
  colors: ThemeColors;
}

/** Shared spacing and radii, so cards, chips, and controls stay on one rhythm. */
export const space = { xs: 4, sm: 8, md: 12, lg: 18, xl: 24, xxl: 32 } as const;
export const radius = { sm: 14, md: 16, lg: 24, pill: 999 } as const;
/** Every tappable control is at least this tall, which keeps touch targets accessible. */
export const minTapTarget = 46;

export const lightTheme: Theme = {
  dark: false,
  colors: {
    background: '#F8F4E8',
    backgroundEnd: '#DDEBDD',
    surface: 'rgba(255,255,255,0.78)',
    surfaceStrong: '#FFFFFF',
    border: 'rgba(35,61,42,0.11)',
    text: '#1D2C22',
    secondaryText: '#647168',
    accent: '#2E7A4F',
    accentStrong: '#225D3D',
    onAccent: '#FFFFFF',
    mint: '#BDE0C3',
    warning: '#B9602D',
    danger: '#B13E45',
    chrome: 'rgba(250,252,248,0.9)',
    shadow: 'rgba(20,50,30,0.18)',
  },
};

export const darkTheme: Theme = {
  dark: true,
  colors: {
    background: '#111A14',
    backgroundEnd: '#1D3023',
    surface: 'rgba(31,48,37,0.82)',
    surfaceStrong: '#22362A',
    border: 'rgba(218,238,221,0.13)',
    text: '#F2F7F0',
    secondaryText: '#B2BFB5',
    accent: '#73C692',
    accentStrong: '#91D4A8',
    onAccent: '#102016',
    mint: '#315C3F',
    warning: '#E69A68',
    danger: '#EE858B',
    chrome: 'rgba(24,39,29,0.94)',
    shadow: 'rgba(0,0,0,0.38)',
  },
};

export const resolveTheme = (mode: ColorMode, system: ColorSchemeName): Theme =>
  mode === 'dark' || (mode === 'system' && system === 'dark') ? darkTheme : lightTheme;

/** Translucent fill derived from a solid color, used for pills and soft button backgrounds. */
export const tint = (color: string, alpha = '1F'): string => `${color}${alpha}`;
