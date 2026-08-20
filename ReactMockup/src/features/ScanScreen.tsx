import { MaterialCommunityIcons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useRouter } from 'expo-router';
import React, { useCallback, useRef, useState } from 'react';
import { Image, StyleSheet, Text, View } from 'react-native';
import { starterCatalog } from '@/data/catalog';
import { scanModeLabels, scanModeOrder } from '@/domain/labels';
import type { PlantSpecies, ScanCandidate, ScanMode } from '@/domain/types';
import { services } from '@/services';
import { Button, Card, ChoiceChips, DemoBadge, RowDivider, Screen, space, useTheme } from '@/ui';

const catalogMatch = (candidate: ScanCandidate): PlantSpecies | undefined =>
  starterCatalog.find((species) =>
    species.scientificName.toLocaleLowerCase() === candidate.scientificName?.toLocaleLowerCase()
    || species.commonName.toLocaleLowerCase() === candidate.title.toLocaleLowerCase());

export function ScanScreen() {
  const [mode, setMode] = useState<ScanMode>('both');
  const [imageUri, setImageUri] = useState<string>();
  const [results, setResults] = useState<ScanCandidate[]>([]);
  const [scanning, setScanning] = useState(false);
  const [error, setError] = useState<string>();
  const theme = useTheme();
  const router = useRouter();

  // Identifies the newest scan so a slow earlier request cannot overwrite a later result.
  const activeScan = useRef(0);

  const scan = useCallback(async (uri: string, scanMode: ScanMode) => {
    const scanId = activeScan.current + 1;
    activeScan.current = scanId;
    setScanning(true);
    setResults([]);
    setError(undefined);

    try {
      const candidates = await services.identification.identify(uri, scanMode);
      if (activeScan.current !== scanId) return;
      setResults(candidates);
    } catch {
      if (activeScan.current !== scanId) return;
      setError('The demo scanner could not finish that image.');
    } finally {
      if (activeScan.current === scanId) setScanning(false);
    }
  }, []);

  const choosePhoto = useCallback(async (fromCamera: boolean) => {
    const permission = fromCamera
      ? await ImagePicker.requestCameraPermissionsAsync()
      : await ImagePicker.requestMediaLibraryPermissionsAsync();

    if (!permission.granted) {
      setError(`Please allow ${fromCamera ? 'camera' : 'photo library'} access to test this flow.`);
      return;
    }

    const result = fromCamera
      ? await ImagePicker.launchCameraAsync({ mediaTypes: ['images'], quality: 0.82 })
      : await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.82 });

    if (result.canceled) return;
    const uri = result.assets[0]?.uri;
    if (!uri) return;

    setImageUri(uri);
    await scan(uri, mode);
  }, [mode, scan]);

  return (
    <Screen title="Plant Scanner" subtitle="Try the camera or a saved image, then compare suggestions before choosing.">
      <DemoBadge label="Demo scanner — no image is uploaded" />

      <Card>
        <ChoiceChips values={scanModeOrder} value={mode} labels={scanModeLabels} onChange={setMode} />

        {imageUri ? (
          <Image source={{ uri: imageUri }} style={styles.preview} accessibilityLabel="Selected plant photo" />
        ) : (
          <View accessible style={[styles.placeholder, { backgroundColor: `${theme.colors.mint}80` }]}>
            <MaterialCommunityIcons name="line-scan" size={58} color={theme.colors.accentStrong} />
            <Text style={[styles.placeholderTitle, { color: theme.colors.text }]}>Fill the frame with one plant</Text>
            <Text style={[styles.center, { color: theme.colors.secondaryText }]}>
              Clear leaf and stem details improve suggestions.
            </Text>
          </View>
        )}

        <View style={styles.actions}>
          <Button label="Camera" icon="camera" disabled={scanning} onPress={() => void choosePhoto(true)} />
          <Button label="Photo Library" icon="image-multiple" kind="secondary" disabled={scanning} onPress={() => void choosePhoto(false)} />
          {imageUri ? (
            <Button label="Scan again" icon="refresh" kind="secondary" loading={scanning} onPress={() => void scan(imageUri, mode)} />
          ) : null}
        </View>
      </Card>

      {scanning ? (
        <Card>
          <View style={styles.loading}>
            <MaterialCommunityIcons name="creation" size={26} color={theme.colors.accent} />
            <Text style={{ color: theme.colors.secondaryText }}>Comparing visible features…</Text>
          </View>
        </Card>
      ) : null}

      {error ? <Card><Text style={{ color: theme.colors.warning }}>{error}</Text></Card> : null}

      {results.length > 0 ? (
        <Card title="Suggestions">
          <Text style={{ color: theme.colors.secondaryText }}>
            Compare candidates before choosing. Confidence is not certainty.
          </Text>

          {results.map((candidate, index) => {
            const match = catalogMatch(candidate);
            return (
              <React.Fragment key={candidate.id}>
                <RowDivider index={index} />
                <View style={styles.result}>
                  <View style={styles.resultHeader}>
                    <View style={styles.resultText}>
                      <Text style={[styles.resultTitle, { color: theme.colors.text }]}>{candidate.title}</Text>
                      {candidate.scientificName ? (
                        <Text style={[styles.scientific, { color: theme.colors.secondaryText }]}>{candidate.scientificName}</Text>
                      ) : null}
                    </View>
                    <Text style={[styles.percent, { color: theme.colors.text }]}>
                      {Math.round(candidate.confidence * 100)}%
                    </Text>
                  </View>

                  <View
                    accessibilityRole="progressbar"
                    accessibilityValue={{ min: 0, max: 100, now: Math.round(candidate.confidence * 100) }}
                    style={[styles.track, { backgroundColor: theme.colors.border }]}
                  >
                    <View style={[styles.progress, { backgroundColor: theme.colors.accent, width: `${candidate.confidence * 100}%` }]} />
                  </View>

                  <Text style={{ color: theme.colors.text }}>{candidate.detail}</Text>
                  <Text style={[styles.source, { color: theme.colors.secondaryText }]}>{candidate.source}</Text>

                  {match ? (
                    <Button
                      label="Use this identification"
                      kind="secondary"
                      onPress={() => router.push({ pathname: '/add-plant', params: { speciesId: match.id } })}
                    />
                  ) : null}
                </View>
              </React.Fragment>
            );
          })}
        </Card>
      ) : null}

      <Card title="Privacy and limits">
        <Text style={{ color: theme.colors.secondaryText }}>
          This mockup keeps the selected image on your device and returns fixed demo suggestions.
        </Text>
        <Text style={{ color: theme.colors.secondaryText }}>
          Health results are possibilities, not diagnoses.
        </Text>
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  preview: { width: '100%', height: 280, borderRadius: 24 },
  placeholder: { minHeight: 250, borderRadius: 24, alignItems: 'center', justifyContent: 'center', gap: space.md, padding: 22 },
  placeholderTitle: { fontSize: 18, fontWeight: '800' },
  center: { textAlign: 'center' },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm + 2 },
  loading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: space.sm + 2 },
  result: { gap: 9 },
  resultHeader: { flexDirection: 'row', justifyContent: 'space-between', gap: space.md },
  resultText: { flex: 1, gap: 2 },
  resultTitle: { fontSize: 17, fontWeight: '800' },
  scientific: { fontStyle: 'italic' },
  percent: { fontSize: 17, fontWeight: '800' },
  track: { height: 7, borderRadius: 999, overflow: 'hidden' },
  progress: { height: '100%', borderRadius: 999 },
  source: { fontSize: 12 },
});
