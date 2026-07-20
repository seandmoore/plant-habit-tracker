import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useMemo } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { GlassCard } from '@/components/GlassCard';
import { PlantArtwork } from '@/components/PlantArtwork';
import { Screen } from '@/components/Screen';
import { StatusPill } from '@/components/StatusPill';
import { wateringRecommendation } from '@/domain/recommendations';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

const statusRank = { overdue: 0, dueToday: 1, upcoming: 2 } as const;

export default function TodayScreen() {
  const { state, logWatering } = usePlantStore();
  const theme = usePlantTheme();
  const router = useRouter();
  const items = useMemo(() => state.plants.map((plant) => ({ plant, recommendation: wateringRecommendation(plant) }))
    .sort((a, b) => statusRank[a.recommendation.status] - statusRank[b.recommendation.status]
      || a.recommendation.dueDate.localeCompare(b.recommendation.dueDate)), [state.plants]);
  const start = Date.now() - 7 * 86_400_000;
  const recentCount = state.plants.flatMap((plant) => plant.careEvents).filter((event) => event.kind === 'watered' && new Date(event.timestamp).getTime() >= start).length;

  return (
    <Screen
      title={greeting()}
      subtitle={`${new Intl.DateTimeFormat(undefined, { weekday: 'long', month: 'long', day: 'numeric' }).format(new Date())}\nCare is an observation, not a perfect streak.`}
    >
      {items.length === 0 ? (
        <GlassCard>
          <View style={styles.empty}>
            <MaterialCommunityIcons name="leaf-circle" size={54} color={theme.colors.accent} />
            <Text style={[styles.emptyTitle, { color: theme.colors.text }]}>Grow your first collection</Text>
            <Text style={[styles.center, { color: theme.colors.secondaryText }]}>Add a plant to start gentle care checks and watering history.</Text>
            <AppButton label="Open My Plants" onPress={() => router.replace('/plants')} />
          </View>
        </GlassCard>
      ) : (
        <GlassCard title="Care checks">
          {items.map(({ plant, recommendation }, index) => (
            <View key={plant.id} style={[styles.careRow, index > 0 && { borderTopColor: theme.colors.border, borderTopWidth: 1, paddingTop: 14 }]}>
              <Pressable style={styles.plantLink} onPress={() => router.push({ pathname: '/plant/[id]', params: { id: plant.id } })}>
                <PlantArtwork photoUri={plant.photoUri} size={60} />
                <View style={styles.careText}>
                  <Text style={[styles.plantName, { color: theme.colors.text }]}>{plant.nickname}</Text>
                  <StatusPill recommendation={recommendation} />
                </View>
              </Pressable>
              {recommendation.status !== 'upcoming' ? (
                <Pressable accessibilityRole="button" accessibilityLabel={`Water ${plant.nickname}`} onPress={() => logWatering(plant.id)} style={[styles.waterButton, { backgroundColor: theme.colors.accent }]}>
                  <MaterialCommunityIcons name="water" size={21} color="#FFFFFF" />
                </Pressable>
              ) : null}
            </View>
          ))}
        </GlassCard>
      )}

      <GlassCard title="Last 7 days">
        <View style={styles.habitRow}>
          <Text style={[styles.count, { color: theme.colors.text }]}>{recentCount}</Text>
          <Text style={[styles.habitText, { color: theme.colors.secondaryText }]}>{recentCount === 1 ? 'watering logged' : 'waterings logged'}</Text>
          <MaterialCommunityIcons name="chart-bar" size={28} color={theme.colors.accent} />
        </View>
        <Text style={{ color: theme.colors.secondaryText }}>The history is here to reveal patterns—not to judge missed days.</Text>
      </GlassCard>
    </Screen>
  );
}

const greeting = () => {
  const hour = new Date().getHours();
  return hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
};

const styles = StyleSheet.create({
  careRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  plantLink: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 13 },
  careText: { flex: 1, gap: 6 },
  plantName: { fontSize: 17, fontWeight: '800' },
  waterButton: { width: 46, height: 46, borderRadius: 16, alignItems: 'center', justifyContent: 'center' },
  habitRow: { flexDirection: 'row', alignItems: 'baseline', gap: 9 },
  count: { fontSize: 38, fontWeight: '900' },
  habitText: { flex: 1, fontSize: 16 },
  empty: { alignItems: 'center', gap: 12, paddingVertical: 12 },
  emptyTitle: { fontSize: 21, fontWeight: '800' },
  center: { textAlign: 'center' },
});
