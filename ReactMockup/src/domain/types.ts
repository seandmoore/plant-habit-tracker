export type PlantEnvironment = 'indoor' | 'outdoorContainer' | 'outdoorGround';
export type LightLevel = 'low' | 'medium' | 'brightIndirect' | 'direct';
export type WaterUnit = 'mL' | 'fl oz';
export type CareEventKind = 'watered' | 'fertilized' | 'pruned' | 'repotted' | 'healthNote';
export type ScanMode = 'species' | 'health' | 'both';

export interface PlantSpecies {
  id: string;
  commonName: string;
  scientificName: string;
  summary: string;
  baselineWateringDays: number;
  light: string;
  soil: string;
  humidity: string;
  environments: PlantEnvironment[];
  toxicityNote?: string;
  icon: string;
}

export interface CareEvent {
  id: string;
  kind: CareEventKind;
  timestamp: string;
  amount?: number;
  waterUnit?: WaterUnit;
  note: string;
}

export interface UserPlant {
  id: string;
  nickname: string;
  speciesId: string;
  commonName: string;
  scientificName: string;
  environment: PlantEnvironment;
  light: LightLevel;
  locationName: string;
  dateAdded: string;
  baselineWateringDays: number;
  reminderEnabled: boolean;
  reminderHour: number;
  notes: string;
  photoUri?: string;
  careEvents: CareEvent[];
}

export type RecommendationStatus = 'overdue' | 'dueToday' | 'upcoming';

export interface CareRecommendation {
  plantId: string;
  dueDate: string;
  intervalDays: number;
  status: RecommendationStatus;
  title: string;
  reason: string;
}

export interface ScanCandidate {
  id: string;
  title: string;
  scientificName?: string;
  confidence: number;
  detail: string;
  source: string;
}

export interface CompanionMessage {
  id: string;
  role: 'companion' | 'user';
  text: string;
}

export type ColorMode = 'system' | 'light' | 'dark';

export interface PersistedPlantState {
  version: 1;
  plants: UserPlant[];
  hasCompletedOnboarding: boolean;
  colorMode: ColorMode;
}
