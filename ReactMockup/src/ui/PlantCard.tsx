import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { CareQueueEntry } from '@/domain/types';
import { Card } from './Card';
import { PlantArtwork } from './PlantArtwork';
import { StatusPill } from './StatusPill';
import { space } from './theme';
import { useTheme } from './ThemeProvider';

/** One plant in the collection grid. The whole card is a single accessible button. */
export function PlantCard({ entry, onPress }: { entry: CareQueueEntry; onPress(): void }) {
  const theme = useTheme();
  const { plant, recommendation } = entry;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${plant.nickname}, ${plant.commonName}, ${recommendation.title}`}
      onPress={onPress}
    >
      <Card>
        <View style={styles.row}>
          <PlantArtwork photoUri={plant.photoUri} />
          <View style={styles.details}>
            <Text style={[styles.name, { color: theme.colors.text }]}>{plant.nickname}</Text>
            <Text style={[styles.species, { color: theme.colors.secondaryText }]}>{plant.commonName}</Text>
            <StatusPill recommendation={recommendation} />
          </View>
          <MaterialCommunityIcons name="chevron-right" size={24} color={theme.colors.secondaryText} />
        </View>
      </Card>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: space.md + 2 },
  details: { flex: 1, gap: space.xs + 1 },
  name: { fontSize: 19, fontWeight: '800' },
  species: { fontSize: 14 },
});
