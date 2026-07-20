import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { AppTextInput } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { PlantArtwork } from '@/components/PlantArtwork';
import { Screen } from '@/components/Screen';
import { starterCatalog } from '@/data/catalog';
import { usePlantTheme } from '@/theme/ThemeProvider';

export default function DiscoverScreen() {
  const [query, setQuery] = useState('');
  const theme = usePlantTheme();
  const router = useRouter();
  const results = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase();
    return normalized ? starterCatalog.filter((plant) => plant.commonName.toLocaleLowerCase().includes(normalized) || plant.scientificName.toLocaleLowerCase().includes(normalized)) : starterCatalog;
  }, [query]);

  return (
    <Screen title="Discover" subtitle="Search a curated starter catalog by common or scientific name.">
      <AppTextInput accessibilityLabel="Search plant catalog" placeholder="Common or scientific name" value={query} onChangeText={setQuery} />
      <GlassCard>
        {results.map((species, index) => (
          <Pressable
            key={species.id}
            accessibilityRole="button"
            onPress={() => router.push({ pathname: '/species/[id]', params: { id: species.id } })}
            style={[styles.row, index > 0 && { borderTopColor: theme.colors.border, borderTopWidth: 1, paddingTop: 13 }]}
          >
            <PlantArtwork size={58} icon={species.icon} />
            <View style={styles.details}>
              <Text style={[styles.name, { color: theme.colors.text }]}>{species.commonName}</Text>
              <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{species.scientificName}</Text>
              <Text numberOfLines={2} style={[styles.summary, { color: theme.colors.secondaryText }]}>{species.summary}</Text>
            </View>
            <MaterialCommunityIcons name="chevron-right" size={23} color={theme.colors.secondaryText} />
          </Pressable>
        ))}
        {results.length === 0 ? <Text style={{ color: theme.colors.secondaryText }}>No catalog plants match “{query}”.</Text> : null}
      </GlassCard>
    </Screen>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 13, paddingVertical: 4 },
  details: { flex: 1, gap: 3 },
  name: { fontSize: 17, fontWeight: '800' },
  scientific: { fontSize: 14, fontStyle: 'italic' },
  summary: { fontSize: 12, lineHeight: 17 },
});
