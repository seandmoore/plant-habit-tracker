import { ColorSchemeName } from 'react-native';
import { ColorMode } from '@/domain/types';

export interface PlantTheme {
  dark: boolean;
  colors: {
    background: string;
    backgroundEnd: string;
    surface: string;
    surfaceStrong: string;
    border: string;
    text: string;
    secondaryText: string;
    accent: string;
    accentStrong: string;
    mint: string;
    warning: string;
    danger: string;
    tab: string;
    shadow: string;
  };
}

const lightTheme: PlantTheme = {
  dark: false,
  colors: {
    background: '#F8F4E8', backgroundEnd: '#DDEBDD', surface: 'rgba(255,255,255,0.78)',
    surfaceStrong: '#FFFFFF', border: 'rgba(35,61,42,0.11)', text: '#1D2C22', secondaryText: '#647168',
    accent: '#2E7A4F', accentStrong: '#225D3D', mint: '#BDE0C3', warning: '#B9602D', danger: '#B13E45',
    tab: 'rgba(250,252,248,0.9)', shadow: 'rgba(20,50,30,0.18)',
  },
};

const darkTheme: PlantTheme = {
  dark: true,
  colors: {
    background: '#111A14', backgroundEnd: '#1D3023', surface: 'rgba(31,48,37,0.82)',
    surfaceStrong: '#22362A', border: 'rgba(218,238,221,0.13)', text: '#F2F7F0', secondaryText: '#B2BFB5',
    accent: '#73C692', accentStrong: '#91D4A8', mint: '#315C3F', warning: '#E69A68', danger: '#EE858B',
    tab: 'rgba(24,39,29,0.94)', shadow: 'rgba(0,0,0,0.38)',
  },
};

export const resolveTheme = (mode: ColorMode, system: ColorSchemeName): PlantTheme =>
  mode === 'dark' || (mode === 'system' && system === 'dark') ? darkTheme : lightTheme;
