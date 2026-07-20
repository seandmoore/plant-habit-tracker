import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useMemo, useState } from 'react';
import { StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { AppTextInput } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { PlantCard } from '@/components/PlantCard';
import { Screen } from '@/components/Screen';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

export default function PlantsScreen() {
  const { state } = usePlantStore();
  const theme = usePlantTheme();
  const router = useRouter();
  const { width } = useWindowDimensions();
  const [query, setQuery] = useState('');
  const filtered = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase();
    if (!normalized) return state.plants;
    return state.plants.filter((plant) => [plant.nickname, plant.commonName, plant.scientificName].some((value) => value.toLocaleLowerCase().includes(normalized)));
  }, [query, state.plants]);
  const columns = width >= 1180 ? 2 : 1;

  return (
    <Screen title="My Plants" subtitle="A calm home for every plant you care for." action={<AppButton label="Add" icon="plus" onPress={() => router.push('/add-plant')} />}>
      <AppTextInput accessibilityLabel="Search your plants" placeholder="Search your plants" value={query} onChangeText={setQuery} />
      {state.plants.length === 0 ? (
        <GlassCard>
          <View style={styles.empty}>
            <MaterialCommunityIcons name="leaf" size={52} color={theme.colors.accent} />
            <Text style={[styles.emptyTitle, { color: theme.colors.text }]}>No plants yet</Text>
            <Text style={{ color: theme.colors.secondaryText }}>Build your collection one plant at a time.</Text>
            <AppButton label="Add a plant" onPress={() => router.push('/add-plant')} />
          </View>
        </GlassCard>
      ) : (
        <View style={styles.grid}>
          {filtered.map((plant) => (
            <View key={plant.id} style={{ width: columns === 2 ? '48.7%' : '100%' }}>
              <PlantCard plant={plant} onPress={() => router.push({ pathname: '/plant/[id]', params: { id: plant.id } })} />
            </View>
          ))}
          {filtered.length === 0 ? <Text style={{ color: theme.colors.secondaryText }}>No plants match “{query}”.</Text> : null}
        </View>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  empty: { alignItems: 'center', gap: 12, paddingVertical: 16 },
  emptyTitle: { fontSize: 21, fontWeight: '800' },
});
