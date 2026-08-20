import { useLocalSearchParams, useRouter } from 'expo-router';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { findSpecies } from '@/data/catalog';
import { Button, Card, FactRow, MissingRecord, ModalScreen, PlantArtwork, space, useTheme } from '@/ui';

export function SpeciesDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const species = findSpecies(id);
  const theme = useTheme();
  const router = useRouter();

  if (!species) {
    return <MissingRecord title="Plant not found" message="This catalog entry is unavailable." />;
  }

  return (
    <ModalScreen title={species.commonName}>
      <View style={styles.hero}>
        <PlantArtwork size={104} icon={species.icon} />
        <View style={styles.heroText}>
          <Text style={[styles.title, { color: theme.colors.text }]}>{species.commonName}</Text>
          <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{species.scientificName}</Text>
          <Text style={[styles.summary, { color: theme.colors.text }]}>{species.summary}</Text>
        </View>
      </View>

      <Card title="Starting care guide">
        <FactRow icon="white-balance-sunny" label="Light" value={species.light} />
        <FactRow
          icon="water"
          label="Soil check"
          value={`Start around every ${species.baselineWateringDays} days, then adapt from observation`}
        />
        <FactRow icon="layers-triple" label="Soil" value={species.soil} />
        <FactRow icon="water-percent" label="Humidity" value={species.humidity} />
      </Card>

      {species.toxicityNote ? (
        <Card title="Safety note">
          <Text style={{ color: theme.colors.warning }}>{species.toxicityNote}</Text>
          <Text style={{ color: theme.colors.secondaryText }}>
            Verify safety details with a veterinarian, poison-control service, or another authoritative source
            for your situation.
          </Text>
        </Card>
      ) : null}

      <Button
        label="Add to My Plants"
        icon="plus"
        onPress={() => router.push({ pathname: '/add-plant', params: { speciesId: species.id } })}
      />
    </ModalScreen>
  );
}

const styles = StyleSheet.create({
  hero: { flexDirection: 'row', alignItems: 'center', gap: space.lg },
  heroText: { flex: 1, gap: space.xs + 1 },
  title: { fontSize: 28, fontWeight: '900', letterSpacing: -0.7 },
  scientific: { fontStyle: 'italic', fontSize: 16 },
  summary: { fontSize: 17, lineHeight: 24, marginTop: space.xs + 1 },
});
