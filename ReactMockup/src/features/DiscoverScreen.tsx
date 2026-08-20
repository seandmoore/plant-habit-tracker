import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { PlantSpecies } from '@/domain/types';
import { services } from '@/services';
import { Card, PlantArtwork, RowDivider, Screen, space, TextField, useTheme } from '@/ui';

export function DiscoverScreen() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<PlantSpecies[]>([]);
  const [error, setError] = useState<string>();
  const theme = useTheme();
  const router = useRouter();

  // Searching goes through the catalog service rather than the bundled array, so pointing
  // Discover at the Worker's /v1/plants endpoint is a change in one module.
  useEffect(() => {
    let active = true;
    services.catalog
      .search(query)
      .then((species) => {
        if (!active) return;
        setResults(species);
        setError(undefined);
      })
      .catch(() => active && setError('The catalog is unavailable right now.'));
    return () => { active = false; };
  }, [query]);

  return (
    <Screen title="Discover" subtitle="Search a curated starter catalog by common or scientific name.">
      <TextField
        accessibilityLabel="Search plant catalog"
        placeholder="Common or scientific name"
        value={query}
        onChangeText={setQuery}
      />

      <Card>
        {error ? <Text style={{ color: theme.colors.warning }}>{error}</Text> : null}

        {results.map((species, index) => (
          <React.Fragment key={species.id}>
            <RowDivider index={index} />
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`${species.commonName}, ${species.scientificName}`}
              onPress={() => router.push({ pathname: '/species/[id]', params: { id: species.id } })}
              style={styles.row}
            >
              <PlantArtwork size={58} icon={species.icon} />
              <View style={styles.details}>
                <Text style={[styles.name, { color: theme.colors.text }]}>{species.commonName}</Text>
                <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{species.scientificName}</Text>
                <Text numberOfLines={2} style={[styles.summary, { color: theme.colors.secondaryText }]}>{species.summary}</Text>
              </View>
              <MaterialCommunityIcons name="chevron-right" size={23} color={theme.colors.secondaryText} />
            </Pressable>
          </React.Fragment>
        ))}

        {!error && results.length === 0 ? (
          <Text style={{ color: theme.colors.secondaryText }}>No catalog plants match “{query}”.</Text>
        ) : null}
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: space.md + 1, paddingVertical: space.xs },
  details: { flex: 1, gap: 3 },
  name: { fontSize: 17, fontWeight: '800' },
  scientific: { fontSize: 14, fontStyle: 'italic' },
  summary: { fontSize: 12, lineHeight: 17 },
});
