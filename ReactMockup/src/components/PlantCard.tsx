import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { UserPlant } from '@/domain/types';
import { wateringRecommendation } from '@/domain/recommendations';
import { usePlantTheme } from '@/theme/ThemeProvider';
import { GlassCard } from './GlassCard';
import { PlantArtwork } from './PlantArtwork';
import { StatusPill } from './StatusPill';

export function PlantCard({ plant, onPress }: { plant: UserPlant; onPress(): void }) {
  const theme = usePlantTheme();
  const recommendation = wateringRecommendation(plant);
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={`${plant.nickname}, ${plant.commonName}, ${recommendation.title}`} onPress={onPress}>
      <GlassCard>
        <View style={styles.row}>
          <PlantArtwork photoUri={plant.photoUri} />
          <View style={styles.details}>
            <Text style={[styles.name, { color: theme.colors.text }]}>{plant.nickname}</Text>
            <Text style={[styles.species, { color: theme.colors.secondaryText }]}>{plant.commonName}</Text>
            <StatusPill recommendation={recommendation} />
          </View>
          <MaterialCommunityIcons name="chevron-right" size={24} color={theme.colors.secondaryText} />
        </View>
      </GlassCard>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  details: { flex: 1, gap: 5 },
  name: { fontSize: 19, fontWeight: '800' },
  species: { fontSize: 14 },
});
