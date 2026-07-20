import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useMemo } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { GlassCard } from '@/components/GlassCard';
import { ModalScaffold } from '@/components/ModalScaffold';
import { PlantArtwork } from '@/components/PlantArtwork';
import { StatusPill } from '@/components/StatusPill';
import { careEventLabels, environmentLabels, lightLabels } from '@/domain/labels';
import { wateringRecommendation } from '@/domain/recommendations';
import { CareEventKind } from '@/domain/types';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

const eventIcons: Record<CareEventKind, string> = {
  watered: 'water', fertilized: 'creation', pruned: 'content-cut', repotted: 'refresh', healthNote: 'medical-bag',
};

export default function PlantDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { state, logWatering } = usePlantStore();
  const plant = state.plants.find((item) => item.id === id);
  const theme = usePlantTheme();
  const router = useRouter();
  const events = useMemo(() => [...(plant?.careEvents ?? [])].sort((a, b) => b.timestamp.localeCompare(a.timestamp)), [plant?.careEvents]);

  if (!plant) return <ModalScaffold title="Plant not found"><Text style={{ color: theme.colors.secondaryText }}>This plant may have been deleted from the mock collection.</Text></ModalScaffold>;
  const recommendation = wateringRecommendation(plant);

  return (
    <ModalScaffold title={plant.nickname}>
      <View style={styles.hero}>
        <PlantArtwork photoUri={plant.photoUri} size={108} />
        <View style={styles.heroText}>
          <Text style={[styles.commonName, { color: theme.colors.text }]}>{plant.commonName}</Text>
          <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{plant.scientificName}</Text>
          <Text style={{ color: theme.colors.secondaryText }}>{environmentLabels[plant.environment]} · {lightLabels[plant.light]}</Text>
          {plant.locationName ? <Text style={{ color: theme.colors.secondaryText }}>⌖ {plant.locationName}</Text> : null}
        </View>
      </View>

      <GlassCard title="Next care check">
        <StatusPill recommendation={recommendation} />
        <Text style={{ color: theme.colors.secondaryText }}>{recommendation.reason}</Text>
        <Text style={[styles.small, { color: theme.colors.secondaryText }]}>About every {recommendation.intervalDays} days under the recorded conditions.</Text>
      </GlassCard>

      <View style={styles.actions}>
        <AppButton label="Water now" icon="water" onPress={() => logWatering(plant.id)} />
        <AppButton label="Add details" icon="pencil-outline" kind="secondary" onPress={() => router.push({ pathname: '/log-watering', params: { plantId: plant.id } })} />
        <AppButton label="Ask companion" icon="creation" kind="secondary" onPress={() => router.push({ pathname: '/companion', params: { plantId: plant.id } })} />
        <AppButton label="Edit" icon="tune-variant" kind="secondary" onPress={() => router.push({ pathname: '/edit-plant', params: { plantId: plant.id } })} />
      </View>

      <GlassCard title="Care history">
        {events.length === 0 ? <Text style={{ color: theme.colors.secondaryText }}>No care has been logged yet.</Text> : events.map((event, index) => (
          <View key={event.id} style={[styles.event, index > 0 && { borderTopWidth: 1, borderTopColor: theme.colors.border, paddingTop: 13 }]}>
            <MaterialCommunityIcons name={eventIcons[event.kind] as never} size={22} color={theme.colors.accent} />
            <View style={styles.eventText}>
              <Text style={[styles.eventTitle, { color: theme.colors.text }]}>{careEventLabels[event.kind]}</Text>
              <Text style={[styles.small, { color: theme.colors.secondaryText }]}>{new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(event.timestamp))}</Text>
              {event.amount != null && event.waterUnit ? <Text style={{ color: theme.colors.text }}>{event.amount} {event.waterUnit}</Text> : null}
              {event.note ? <Text style={{ color: theme.colors.text }}>{event.note}</Text> : null}
            </View>
          </View>
        ))}
      </GlassCard>

      {plant.notes ? <GlassCard title="Notes"><Text style={{ color: theme.colors.text }}>{plant.notes}</Text></GlassCard> : null}
    </ModalScaffold>
  );
}

const styles = StyleSheet.create({
  hero: { flexDirection: 'row', alignItems: 'center', gap: 18 },
  heroText: { flex: 1, gap: 5 },
  commonName: { fontSize: 25, fontWeight: '900' },
  scientific: { fontSize: 16, fontStyle: 'italic' },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  event: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  eventText: { flex: 1, gap: 3 },
  eventTitle: { fontWeight: '800' },
  small: { fontSize: 12, lineHeight: 17 },
});
