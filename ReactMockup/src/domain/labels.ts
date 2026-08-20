import type { CareEventKind, LightLevel, PlantEnvironment, ScanMode, WaterUnit } from './types';

export const environmentLabels: Record<PlantEnvironment, string> = {
  indoor: 'Indoor',
  outdoorContainer: 'Outdoor pot',
  outdoorGround: 'Garden bed',
};

export const lightLabels: Record<LightLevel, string> = {
  low: 'Low light',
  medium: 'Medium light',
  brightIndirect: 'Bright, indirect',
  direct: 'Direct sun',
};

export const careEventLabels: Record<CareEventKind, string> = {
  watered: 'Watered',
  fertilized: 'Fertilized',
  pruned: 'Pruned',
  repotted: 'Repotted',
  healthNote: 'Health note',
};

export const careEventIcons: Record<CareEventKind, string> = {
  watered: 'water',
  fertilized: 'creation',
  pruned: 'content-cut',
  repotted: 'refresh',
  healthNote: 'medical-bag',
};

export const scanModeLabels: Record<ScanMode, string> = {
  species: 'Species',
  health: 'Health',
  both: 'Both',
};

export const waterUnitLabels: Record<WaterUnit, string> = { 'mL': 'mL', 'fl oz': 'fl oz' };

export const environmentOrder: PlantEnvironment[] = ['indoor', 'outdoorContainer', 'outdoorGround'];
export const lightOrder: LightLevel[] = ['low', 'medium', 'brightIndirect', 'direct'];
export const scanModeOrder: ScanMode[] = ['species', 'health', 'both'];
export const waterUnitOrder: WaterUnit[] = ['mL', 'fl oz'];
