import { CareEventKind, LightLevel, PlantEnvironment } from './types';

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
