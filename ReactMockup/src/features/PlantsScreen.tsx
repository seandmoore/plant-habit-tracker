import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useMemo, useState } from 'react';
import { StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { careQueue, filterPlants } from '@/domain/selectors';
import { usePlants } from '@/state/PlantStore';
import { Button, Card, EmptyState, PlantCard, Screen, space, TextField, useTheme } from '@/ui';

/** Two columns only once a card can hold its content comfortably. */
const TWO_COLUMN_BREAKPOINT = 1180;

export function PlantsScreen() {
  const plants = usePlants();
  const theme = useTheme();
  const router = useRouter();
  const { width } = useWindowDimensions();
  const [query, setQuery] = useState('');

  const entries = useMemo(() => careQueue(filterPlants(plants, query)), [plants, query]);
  const columns = width >= TWO_COLUMN_BREAKPOINT ? 2 : 1;

  return (
    <Screen
      title="My Plants"
      subtitle="A calm home for every plant you care for."
      action={<Button label="Add" icon="plus" onPress={() => router.push('/add-plant')} />}
    >
      <TextField
        accessibilityLabel="Search your plants"
        placeholder="Search your plants"
        value={query}
        onChangeText={setQuery}
      />

      {plants.length === 0 ? (
        <Card>
          <EmptyState
            icon={<MaterialCommunityIcons name="leaf" size={52} color={theme.colors.accent} />}
            title="No plants yet"
            message="Build your collection one plant at a time."
            action={<Button label="Add a plant" onPress={() => router.push('/add-plant')} />}
          />
        </Card>
      ) : (
        <View style={styles.grid}>
          {entries.map((entry) => (
            <View key={entry.plant.id} style={{ width: columns === 2 ? '48.7%' : '100%' }}>
              <PlantCard
                entry={entry}
                onPress={() => router.push({ pathname: '/plant/[id]', params: { id: entry.plant.id } })}
              />
            </View>
          ))}
          {entries.length === 0 ? (
            <Text style={{ color: theme.colors.secondaryText }}>No plants match “{query}”.</Text>
          ) : null}
        </View>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: space.lg - 2 },
});
