import * as ImagePicker from 'expo-image-picker';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { findSpecies, starterCatalog } from '@/data/catalog';
import { environmentLabels, environmentOrder, lightLabels, lightOrder } from '@/domain/labels';
import type { LightLevel, PlantEnvironment } from '@/domain/types';
import { usePlantStore } from '@/state/PlantStore';
import {
  Button,
  Card,
  ChoiceChips,
  FieldLabel,
  Hint,
  ModalScreen,
  PlantArtwork,
  space,
  TextField,
  ToggleRow,
  useTheme,
} from '@/ui';

export function AddPlantScreen() {
  const { speciesId: requestedSpeciesId } = useLocalSearchParams<{ speciesId?: string }>();
  const initialSpecies = findSpecies(requestedSpeciesId) ?? starterCatalog[0];

  const [speciesId, setSpeciesId] = useState(initialSpecies?.id ?? '');
  const [nickname, setNickname] = useState(initialSpecies?.commonName ?? '');
  const [environment, setEnvironment] = useState<PlantEnvironment>('indoor');
  const [light, setLight] = useState<LightLevel>('brightIndirect');
  const [locationName, setLocationName] = useState('');
  const [notes, setNotes] = useState('');
  const [reminderEnabled, setReminderEnabled] = useState(false);
  const [photoUri, setPhotoUri] = useState<string>();

  const species = findSpecies(speciesId);
  const { addPlant } = usePlantStore();
  const theme = useTheme();
  const router = useRouter();

  const choosePhoto = async () => {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) return;
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.82 });
    if (!result.canceled) setPhotoUri(result.assets[0]?.uri);
  };

  /** Keeps the nickname in step with the species until someone types their own. */
  const selectSpecies = (nextId: string) => {
    const next = findSpecies(nextId);
    if (!next) return;
    if (!nickname.trim() || nickname === species?.commonName) setNickname(next.commonName);
    setSpeciesId(nextId);
  };

  const save = () => {
    if (!species) return;
    const id = addPlant({ nickname, species, environment, light, locationName, notes, photoUri, reminderEnabled });
    router.dismissAll();
    router.push({ pathname: '/plant/[id]', params: { id } });
  };

  return (
    <ModalScreen title="Add Plant">
      <Card title="Plant">
        <View style={styles.photoRow}>
          {photoUri
            ? <Image source={{ uri: photoUri }} accessibilityIgnoresInvertColors style={styles.photo} />
            : <PlantArtwork size={78} icon={species?.icon} />}
          <Button
            label={photoUri ? 'Change photo' : 'Choose photo'}
            icon="image"
            kind="secondary"
            onPress={() => void choosePhoto()}
          />
        </View>

        <FieldLabel>Species</FieldLabel>
        <View style={styles.speciesGrid}>
          {starterCatalog.map((item) => {
            const selected = item.id === speciesId;
            return (
              <Pressable
                key={item.id}
                accessibilityRole="radio"
                accessibilityState={{ checked: selected }}
                accessibilityLabel={`${item.commonName}, ${item.scientificName}`}
                onPress={() => selectSpecies(item.id)}
                style={[styles.speciesChoice, {
                  borderColor: selected ? theme.colors.accent : theme.colors.border,
                  backgroundColor: selected ? `${theme.colors.accent}18` : theme.colors.surfaceStrong,
                }]}
              >
                <Text style={[styles.speciesName, { color: theme.colors.text }]}>{item.commonName}</Text>
                <Text numberOfLines={1} style={[styles.speciesLatin, { color: theme.colors.secondaryText }]}>
                  {item.scientificName}
                </Text>
              </Pressable>
            );
          })}
        </View>

        <FieldLabel>Nickname</FieldLabel>
        <TextField value={nickname} onChangeText={setNickname} placeholder="For example, Moss" />
      </Card>

      <Card title="Growing place">
        <FieldLabel>Environment</FieldLabel>
        <ChoiceChips values={environmentOrder} value={environment} labels={environmentLabels} onChange={setEnvironment} />
        <FieldLabel>Light</FieldLabel>
        <ChoiceChips values={lightOrder} value={light} labels={lightLabels} onChange={setLight} />
        <FieldLabel>Room, patio, or bed</FieldLabel>
        <TextField value={locationName} onChangeText={setLocationName} placeholder="Optional" />
      </Card>

      <Card title="Care reminders">
        <ToggleRow label="Remind me to check the soil" value={reminderEnabled} onChange={setReminderEnabled} />
        <Hint>Reminders suggest a soil check. They never mean the plant must be watered.</Hint>
      </Card>

      <Card title="Notes">
        <TextField multiline value={notes} onChangeText={setNotes} placeholder="Anything useful about this plant" />
      </Card>

      <Button label="Add plant" icon="plus" onPress={save} disabled={!species} />
    </ModalScreen>
  );
}

const styles = StyleSheet.create({
  photoRow: { flexDirection: 'row', alignItems: 'center', gap: space.md + 2 },
  photo: { width: 78, height: 78, borderRadius: 22 },
  speciesGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  speciesChoice: { width: '48%', minHeight: 64, justifyContent: 'center', borderRadius: 14, borderWidth: 1, padding: space.sm + 2 },
  speciesName: { fontWeight: '800' },
  speciesLatin: { fontSize: 11, fontStyle: 'italic', marginTop: 2 },
});
