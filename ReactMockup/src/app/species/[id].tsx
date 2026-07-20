import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { GlassCard } from '@/components/GlassCard';
import { ModalScaffold } from '@/components/ModalScaffold';
import { PlantArtwork } from '@/components/PlantArtwork';
import { starterCatalog } from '@/data/catalog';
import { usePlantTheme } from '@/theme/ThemeProvider';

export default function SpeciesDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const species = starterCatalog.find((item) => item.id === id);
  const theme = usePlantTheme();
  const router = useRouter();

  if (!species) return <ModalScaffold title="Plant not found"><Text style={{ color: theme.colors.secondaryText }}>This catalog entry is unavailable.</Text></ModalScaffold>;
  return (
    <ModalScaffold title={species.commonName}>
      <View style={styles.hero}>
        <PlantArtwork size={104} icon={species.icon} />
        <View style={styles.heroText}>
          <Text style={[styles.title, { color: theme.colors.text }]}>{species.commonName}</Text>
          <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{species.scientificName}</Text>
          <Text style={[styles.summary, { color: theme.colors.text }]}>{species.summary}</Text>
        </View>
      </View>

      <GlassCard title="Starting care guide">
        <Fact icon="white-balance-sunny" label="Light" value={species.light} />
        <Fact icon="water" label="Soil check" value={`Start around every ${species.baselineWateringDays} days, then adapt from observation`} />
        <Fact icon="layers-triple" label="Soil" value={species.soil} />
        <Fact icon="water-percent" label="Humidity" value={species.humidity} />
      </GlassCard>

      {species.toxicityNote ? (
        <GlassCard title="Safety note">
          <Text style={{ color: theme.colors.warning }}>{species.toxicityNote}</Text>
          <Text style={{ color: theme.colors.secondaryText }}>Verify safety details with a veterinarian, poison-control service, or another authoritative source for your situation.</Text>
        </GlassCard>
      ) : null}
      <AppButton label="Add to My Plants" icon="plus" onPress={() => router.push({ pathname: '/add-plant', params: { speciesId: species.id } })} />
    </ModalScaffold>
  );
}

function Fact({ icon, label, value }: { icon: string; label: string; value: string }) {
  const theme = usePlantTheme();
  return (
    <View style={styles.fact}>
      <MaterialCommunityIcons name={icon as never} size={22} color={theme.colors.accent} />
      <View style={styles.factText}><Text style={[styles.factLabel, { color: theme.colors.text }]}>{label}</Text><Text style={{ color: theme.colors.secondaryText }}>{value}</Text></View>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: { flexDirection: 'row', alignItems: 'center', gap: 18 },
  heroText: { flex: 1, gap: 5 },
  title: { fontSize: 28, fontWeight: '900', letterSpacing: -0.7 },
  scientific: { fontStyle: 'italic', fontSize: 16 },
  summary: { fontSize: 17, lineHeight: 24, marginTop: 5 },
  fact: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  factText: { flex: 1, gap: 2 },
  factLabel: { fontWeight: '800' },
});
