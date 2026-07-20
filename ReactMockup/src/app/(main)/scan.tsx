import { MaterialCommunityIcons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Image, StyleSheet, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { ChoiceChips, DemoBadge } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { Screen } from '@/components/Screen';
import { starterCatalog } from '@/data/catalog';
import { ScanCandidate, ScanMode } from '@/domain/types';
import { mockIdentificationService } from '@/services/mockServices';
import { usePlantTheme } from '@/theme/ThemeProvider';

const modeLabels: Record<ScanMode, string> = { species: 'Species', health: 'Health', both: 'Both' };

export default function ScanScreen() {
  const [mode, setMode] = useState<ScanMode>('both');
  const [imageUri, setImageUri] = useState<string>();
  const [results, setResults] = useState<ScanCandidate[]>([]);
  const [scanning, setScanning] = useState(false);
  const [error, setError] = useState<string>();
  const theme = usePlantTheme();
  const router = useRouter();

  const scan = async (uri = imageUri) => {
    if (!uri) return;
    setScanning(true);
    setResults([]);
    setError(undefined);
    try { setResults(await mockIdentificationService.identify(uri, mode)); }
    catch { setError('The demo scanner could not finish that image.'); }
    finally { setScanning(false); }
  };

  const choosePhoto = async (camera: boolean) => {
    const permission = camera
      ? await ImagePicker.requestCameraPermissionsAsync()
      : await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) return setError(`Please allow ${camera ? 'camera' : 'photo library'} access to test this flow.`);
    const result = camera
      ? await ImagePicker.launchCameraAsync({ mediaTypes: ['images'], quality: 0.82 })
      : await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.82 });
    if (result.canceled) return;
    const uri = result.assets[0]?.uri;
    if (!uri) return;
    setImageUri(uri);
    await scan(uri);
  };

  return (
    <Screen title="Plant Scanner" subtitle="Try the camera or a saved image, then compare suggestions before choosing.">
      <DemoBadge label="Demo scanner — no image is uploaded" />
      <GlassCard>
        <ChoiceChips values={['species', 'health', 'both']} value={mode} labels={modeLabels} onChange={setMode} />
        {imageUri ? (
          <Image source={{ uri: imageUri }} style={styles.preview} accessibilityLabel="Selected plant" />
        ) : (
          <View style={[styles.placeholder, { backgroundColor: `${theme.colors.mint}80` }]}>
            <MaterialCommunityIcons name="line-scan" size={58} color={theme.colors.accentStrong} />
            <Text style={[styles.placeholderTitle, { color: theme.colors.text }]}>Fill the frame with one plant</Text>
            <Text style={[styles.center, { color: theme.colors.secondaryText }]}>Clear leaf and stem details improve suggestions.</Text>
          </View>
        )}
        <View style={styles.actions}>
          <AppButton label="Camera" icon="camera" onPress={() => void choosePhoto(true)} kind="primary" />
          <AppButton label="Photo Library" icon="image-multiple" onPress={() => void choosePhoto(false)} kind="secondary" />
          {imageUri ? <AppButton label="Scan again" icon="refresh" onPress={() => void scan()} loading={scanning} kind="secondary" /> : null}
        </View>
      </GlassCard>

      {scanning ? <GlassCard><View style={styles.loading}><MaterialCommunityIcons name="creation" size={26} color={theme.colors.accent} /><Text style={{ color: theme.colors.secondaryText }}>Comparing visible features…</Text></View></GlassCard> : null}
      {error ? <GlassCard><Text style={{ color: theme.colors.warning }}>{error}</Text></GlassCard> : null}
      {results.length > 0 ? (
        <GlassCard title="Suggestions">
          <Text style={{ color: theme.colors.secondaryText }}>Compare candidates before choosing. Confidence is not certainty.</Text>
          {results.map((candidate, index) => {
            const match = starterCatalog.find((plant) => plant.scientificName === candidate.scientificName || plant.commonName === candidate.title);
            return (
              <View key={candidate.id} style={[styles.result, index > 0 && { borderTopColor: theme.colors.border, borderTopWidth: 1, paddingTop: 14 }]}>
                <View style={styles.resultHeader}>
                  <View style={styles.resultText}><Text style={[styles.resultTitle, { color: theme.colors.text }]}>{candidate.title}</Text>{candidate.scientificName ? <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{candidate.scientificName}</Text> : null}</View>
                  <Text style={[styles.percent, { color: theme.colors.text }]}>{Math.round(candidate.confidence * 100)}%</Text>
                </View>
                <View style={[styles.track, { backgroundColor: theme.colors.border }]}><View style={[styles.progress, { backgroundColor: theme.colors.accent, width: `${candidate.confidence * 100}%` }]} /></View>
                <Text style={{ color: theme.colors.text }}>{candidate.detail}</Text>
                <Text style={[styles.source, { color: theme.colors.secondaryText }]}>{candidate.source}</Text>
                {match ? <AppButton label="Use this identification" kind="secondary" onPress={() => router.push({ pathname: '/add-plant', params: { speciesId: match.id } })} /> : null}
              </View>
            );
          })}
        </GlassCard>
      ) : null}

      <GlassCard title="Privacy and limits">
        <Text style={{ color: theme.colors.secondaryText }}>This mockup keeps the selected image on your device and returns fixed demo suggestions.</Text>
        <Text style={{ color: theme.colors.secondaryText }}>Health results are possibilities, not diagnoses.</Text>
      </GlassCard>
    </Screen>
  );
}

const styles = StyleSheet.create({
  preview: { width: '100%', height: 280, borderRadius: 24 },
  placeholder: { minHeight: 250, borderRadius: 24, alignItems: 'center', justifyContent: 'center', gap: 12, padding: 22 },
  placeholderTitle: { fontSize: 18, fontWeight: '800' },
  center: { textAlign: 'center' },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  loading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10 },
  result: { gap: 9 },
  resultHeader: { flexDirection: 'row', justifyContent: 'space-between', gap: 12 },
  resultText: { flex: 1, gap: 2 },
  resultTitle: { fontSize: 17, fontWeight: '800' },
  scientific: { fontStyle: 'italic' },
  percent: { fontSize: 17, fontWeight: '800' },
  track: { height: 7, borderRadius: 999, overflow: 'hidden' },
  progress: { height: '100%', borderRadius: 999 },
  source: { fontSize: 12 },
});
