import { PlantSpecies } from '@/domain/types';

export const starterCatalog: PlantSpecies[] = [
  {
    id: 'monstera-deliciosa', commonName: 'Monstera', scientificName: 'Monstera deliciosa',
    summary: 'A bold tropical climber with naturally split leaves.', baselineWateringDays: 9,
    light: 'Bright, indirect light', soil: 'Airy, well-draining mix', humidity: 'Average to humid',
    environments: ['indoor', 'outdoorContainer'], toxicityNote: 'Can irritate people and pets if chewed.', icon: 'leaf',
  },
  {
    id: 'epipremnum-aureum', commonName: 'Golden pothos', scientificName: 'Epipremnum aureum',
    summary: 'An adaptable trailing vine that tolerates a range of indoor conditions.', baselineWateringDays: 10,
    light: 'Low to bright, indirect light', soil: 'Well-draining potting mix', humidity: 'Average',
    environments: ['indoor', 'outdoorContainer'], toxicityNote: 'Can irritate people and pets if chewed.', icon: 'sprout',
  },
  {
    id: 'sansevieria-trifasciata', commonName: 'Snake plant', scientificName: 'Dracaena trifasciata',
    summary: 'A resilient succulent-like houseplant with upright leaves.', baselineWateringDays: 18,
    light: 'Low to bright light', soil: 'Fast-draining succulent mix', humidity: 'Average to dry',
    environments: ['indoor', 'outdoorContainer'], toxicityNote: 'May be harmful to pets if eaten.', icon: 'grass',
  },
  {
    id: 'ficus-lyrata', commonName: 'Fiddle-leaf fig', scientificName: 'Ficus lyrata',
    summary: 'A statement plant that appreciates consistency and bright filtered light.', baselineWateringDays: 9,
    light: 'Bright, indirect light', soil: 'Rich, well-draining mix', humidity: 'Average to humid',
    environments: ['indoor', 'outdoorContainer'], toxicityNote: 'Sap can irritate skin; harmful if eaten.', icon: 'tree',
  },
  {
    id: 'chlorophytum-comosum', commonName: 'Spider plant', scientificName: 'Chlorophytum comosum',
    summary: 'An easy arching plant that produces small plantlets.', baselineWateringDays: 7,
    light: 'Medium to bright, indirect light', soil: 'General potting mix', humidity: 'Average',
    environments: ['indoor', 'outdoorContainer'], icon: 'flower-tulip',
  },
  {
    id: 'lavandula-angustifolia', commonName: 'English lavender', scientificName: 'Lavandula angustifolia',
    summary: 'A fragrant, sun-loving perennial for containers and garden beds.', baselineWateringDays: 8,
    light: 'Full sun', soil: 'Lean, sharply drained soil', humidity: 'Dry with good airflow',
    environments: ['outdoorContainer', 'outdoorGround'], toxicityNote: 'Concentrated oils may be harmful if ingested.', icon: 'flower',
  },
  {
    id: 'ocimum-basilicum', commonName: 'Basil', scientificName: 'Ocimum basilicum',
    summary: 'A tender culinary herb that grows quickly in warmth and sun.', baselineWateringDays: 3,
    light: 'Full to partial sun', soil: 'Moist, fertile, well-draining soil', humidity: 'Average',
    environments: ['indoor', 'outdoorContainer', 'outdoorGround'], icon: 'leaf',
  },
  {
    id: 'solanum-lycopersicum', commonName: 'Tomato', scientificName: 'Solanum lycopersicum',
    summary: 'A productive warm-season crop that needs sun and consistent moisture.', baselineWateringDays: 3,
    light: 'Full sun', soil: 'Fertile, moisture-retentive soil', humidity: 'Average with airflow',
    environments: ['outdoorContainer', 'outdoorGround'], toxicityNote: 'Leaves and stems should not be eaten.', icon: 'food-apple',
  },
  {
    id: 'rosa', commonName: 'Garden rose', scientificName: 'Rosa spp.',
    summary: 'A flowering shrub with many forms, colors, and growth habits.', baselineWateringDays: 6,
    light: 'Full sun', soil: 'Rich, well-draining soil', humidity: 'Average with airflow',
    environments: ['outdoorContainer', 'outdoorGround'], toxicityNote: 'Thorns can cause injury.', icon: 'flower-poppy',
  },
  {
    id: 'acer-palmatum', commonName: 'Japanese maple', scientificName: 'Acer palmatum',
    summary: 'A graceful small tree valued for form and seasonal leaf color.', baselineWateringDays: 7,
    light: 'Morning sun or filtered light', soil: 'Moist, well-draining soil', humidity: 'Average',
    environments: ['outdoorContainer', 'outdoorGround'], icon: 'tree-outline',
  },
];
