import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useMemo } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { careEventIcons, careEventLabels, environmentLabels, lightLabels } from '@/domain/labels';
import { careHistory } from '@/domain/selectors';
import { wateringRecommendation } from '@/domain/wateringPlanner';
import { usePlantStore } from '@/state/PlantStore';
import { usePlant } from '@/state/selectors';
import {
  Button,
  Card,
  MissingRecord,
  ModalScreen,
  PlantArtwork,
  RowDivider,
  space,
  StatusPill,
  useTheme,
} from '@/ui';

export function PlantDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const plant = usePlant(id);
  const { logWatering } = usePlantStore();
  const theme = useTheme();
  const router = useRouter();

  const events = useMemo(() => (plant ? careHistory(plant) : []), [plant]);

  if (!plant) {
    return <MissingRecord title="Plant not found" message="This plant may have been deleted from the mock collection." />;
  }

  const recommendation = wateringRecommendation(plant);

  return (
    <ModalScreen title={plant.nickname}>
      <View style={styles.hero}>
        <PlantArtwork photoUri={plant.photoUri} size={108} />
        <View style={styles.heroText}>
          <Text style={[styles.commonName, { color: theme.colors.text }]}>{plant.commonName}</Text>
          <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{plant.scientificName}</Text>
          <Text style={{ color: theme.colors.secondaryText }}>
            {environmentLabels[plant.environment]} · {lightLabels[plant.light]}
          </Text>
          {plant.locationName ? (
            <Text style={{ color: theme.colors.secondaryText }}>⌖ {plant.locationName}</Text>
          ) : null}
        </View>
      </View>

      <Card title="Next care check">
        <StatusPill recommendation={recommendation} />
        <Text style={{ color: theme.colors.secondaryText }}>{recommendation.reason}</Text>
        <Text style={[styles.small, { color: theme.colors.secondaryText }]}>
          About every {recommendation.intervalDays} days under the recorded conditions.
        </Text>
      </Card>

      <View style={styles.actions}>
        <Button label="Water now" icon="water" onPress={() => logWatering(plant.id)} />
        <Button
          label="Add details"
          icon="pencil-outline"
          kind="secondary"
          onPress={() => router.push({ pathname: '/log-watering', params: { plantId: plant.id } })}
        />
        <Button
          label="Ask companion"
          icon="creation"
          kind="secondary"
          onPress={() => router.push({ pathname: '/companion', params: { plantId: plant.id } })}
        />
        <Button
          label="Edit"
          icon="tune-variant"
          kind="secondary"
          onPress={() => router.push({ pathname: '/edit-plant', params: { plantId: plant.id } })}
        />
      </View>

      <Card title="Care history">
        {events.length === 0 ? (
          <Text style={{ color: theme.colors.secondaryText }}>No care has been logged yet.</Text>
        ) : (
          events.map((event, index) => (
            <React.Fragment key={event.id}>
              <RowDivider index={index} />
              <View style={styles.event}>
                <MaterialCommunityIcons name={careEventIcons[event.kind] as never} size={22} color={theme.colors.accent} />
                <View style={styles.eventText}>
                  <Text style={[styles.eventTitle, { color: theme.colors.text }]}>{careEventLabels[event.kind]}</Text>
                  <Text style={[styles.small, { color: theme.colors.secondaryText }]}>
                    {new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(event.timestamp))}
                  </Text>
                  {event.amount != null && event.waterUnit ? (
                    <Text style={{ color: theme.colors.text }}>{event.amount} {event.waterUnit}</Text>
                  ) : null}
                  {event.note ? <Text style={{ color: theme.colors.text }}>{event.note}</Text> : null}
                </View>
              </View>
            </React.Fragment>
          ))
        )}
      </Card>

      {plant.notes ? (
        <Card title="Notes"><Text style={{ color: theme.colors.text }}>{plant.notes}</Text></Card>
      ) : null}
    </ModalScreen>
  );
}

const styles = StyleSheet.create({
  hero: { flexDirection: 'row', alignItems: 'center', gap: space.lg },
  heroText: { flex: 1, gap: space.xs + 1 },
  commonName: { fontSize: 25, fontWeight: '900' },
  scientific: { fontSize: 16, fontStyle: 'italic' },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm + 2 },
  event: { flexDirection: 'row', alignItems: 'flex-start', gap: space.md },
  eventText: { flex: 1, gap: 3 },
  eventTitle: { fontWeight: '800' },
  small: { fontSize: 12, lineHeight: 17 },
});
