import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { needsAttention } from '@/domain/selectors';
import type { CareQueueEntry } from '@/domain/types';
import { usePlantStore } from '@/state/PlantStore';
import { useCareQueue, useWateringsThisWeek } from '@/state/selectors';
import {
  Button,
  Card,
  EmptyState,
  IconButton,
  PlantArtwork,
  RowDivider,
  Screen,
  space,
  StatusPill,
  useTheme,
} from '@/ui';

const greeting = (now = new Date()): string => {
  const hour = now.getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
};

const todayLabel = (now = new Date()): string =>
  new Intl.DateTimeFormat(undefined, { weekday: 'long', month: 'long', day: 'numeric' }).format(now);

export function TodayScreen() {
  const queue = useCareQueue();
  const wateringsThisWeek = useWateringsThisWeek();
  const theme = useTheme();
  const router = useRouter();

  return (
    <Screen title={greeting()} subtitle={`${todayLabel()}\nCare is an observation, not a perfect streak.`}>
      {queue.length === 0 ? (
        <Card>
          <EmptyState
            icon={<MaterialCommunityIcons name="leaf-circle" size={54} color={theme.colors.accent} />}
            title="Grow your first collection"
            message="Add a plant to start gentle care checks and watering history."
            action={<Button label="Open My Plants" onPress={() => router.replace('/plants')} />}
          />
        </Card>
      ) : (
        <Card title="Care checks">
          {queue.map((entry, index) => (
            <React.Fragment key={entry.plant.id}>
              <RowDivider index={index} />
              <CareRow entry={entry} />
            </React.Fragment>
          ))}
        </Card>
      )}

      <Card title="Last 7 days">
        <View style={styles.habitRow}>
          <Text style={[styles.count, { color: theme.colors.text }]}>{wateringsThisWeek}</Text>
          <Text style={[styles.habitText, { color: theme.colors.secondaryText }]}>
            {wateringsThisWeek === 1 ? 'watering logged' : 'waterings logged'}
          </Text>
          <MaterialCommunityIcons name="chart-bar" size={28} color={theme.colors.accent} />
        </View>
        <Text style={{ color: theme.colors.secondaryText }}>
          The history is here to reveal patterns—not to judge missed days.
        </Text>
      </Card>
    </Screen>
  );
}

function CareRow({ entry }: { entry: CareQueueEntry }) {
  const { logWatering } = usePlantStore();
  const theme = useTheme();
  const router = useRouter();
  const { plant, recommendation } = entry;

  return (
    <View style={styles.careRow}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${plant.nickname}, ${recommendation.title}`}
        style={styles.plantLink}
        onPress={() => router.push({ pathname: '/plant/[id]', params: { id: plant.id } })}
      >
        <PlantArtwork photoUri={plant.photoUri} size={60} />
        <View style={styles.careText}>
          <Text style={[styles.plantName, { color: theme.colors.text }]}>{plant.nickname}</Text>
          <StatusPill recommendation={recommendation} />
        </View>
      </Pressable>

      {needsAttention(entry) ? (
        <IconButton icon="water" tone="accent" label={`Water ${plant.nickname}`} onPress={() => logWatering(plant.id)} />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  careRow: { flexDirection: 'row', alignItems: 'center', gap: space.sm + 2 },
  plantLink: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: space.md + 1 },
  careText: { flex: 1, gap: space.xs + 2 },
  plantName: { fontSize: 17, fontWeight: '800' },
  habitRow: { flexDirection: 'row', alignItems: 'baseline', gap: 9 },
  count: { fontSize: 38, fontWeight: '900' },
  habitText: { flex: 1, fontSize: 16 },
});
