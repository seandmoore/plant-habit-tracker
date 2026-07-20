import * as ImagePicker from 'expo-image-picker';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useMemo, useState } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { AppTextInput, ChoiceChips, FieldLabel } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { ModalScaffold } from '@/components/ModalScaffold';
import { PlantArtwork } from '@/components/PlantArtwork';
import { starterCatalog } from '@/data/catalog';
import { environmentLabels, lightLabels } from '@/domain/labels';
import { LightLevel, PlantEnvironment } from '@/domain/types';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

export default function AddPlantScreen() {
  const params = useLocalSearchParams<{ speciesId?: string }>();
  const initialSpecies = starterCatalog.find((item) => item.id === params.speciesId) ?? starterCatalog[0];
  const [speciesId, setSpeciesId] = useState(initialSpecies?.id ?? '');
  const [nickname, setNickname] = useState(initialSpecies?.commonName ?? '');
  const [environment, setEnvironment] = useState<PlantEnvironment>('indoor');
  const [light, setLight] = useState<LightLevel>('brightIndirect');
  const [locationName, setLocationName] = useState('');
  const [notes, setNotes] = useState('');
  const [photoUri, setPhotoUri] = useState<string>();
  const species = useMemo(() => starterCatalog.find((item) => item.id === speciesId), [speciesId]);
  const { addPlant } = usePlantStore();
  const theme = usePlantTheme();
  const router = useRouter();

  const choosePhoto = async () => {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) return;
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.82 });
    if (!result.canceled) setPhotoUri(result.assets[0]?.uri);
  };

  const save = () => {
    if (!species) return;
    const id = addPlant({ nickname, species, environment, light, locationName, notes, photoUri });
    router.dismissAll();
    router.push({ pathname: '/plant/[id]', params: { id } });
  };

  return (
    <ModalScaffold title="Add Plant">
      <GlassCard title="Plant">
        <View style={styles.photoRow}>
          {photoUri ? <Image source={{ uri: photoUri }} style={styles.photo} /> : <PlantArtwork size={78} icon={species?.icon} />}
          <AppButton label={photoUri ? 'Change photo' : 'Choose photo'} icon="image" kind="secondary" onPress={() => void choosePhoto()} />
        </View>
        <FieldLabel>Species</FieldLabel>
        <View style={styles.speciesGrid}>
          {starterCatalog.map((item) => {
            const selected = item.id === speciesId;
            return (
              <Pressable key={item.id} accessibilityRole="radio" accessibilityState={{ checked: selected }} onPress={() => { setSpeciesId(item.id); if (!nickname.trim() || nickname === species?.commonName) setNickname(item.commonName); }} style={[styles.speciesChoice, { borderColor: selected ? theme.colors.accent : theme.colors.border, backgroundColor: selected ? `${theme.colors.accent}18` : theme.colors.surfaceStrong }]}>
                <Text style={[styles.speciesName, { color: theme.colors.text }]}>{item.commonName}</Text>
                <Text numberOfLines={1} style={[styles.speciesLatin, { color: theme.colors.secondaryText }]}>{item.scientificName}</Text>
              </Pressable>
            );
          })}
        </View>
        <FieldLabel>Nickname</FieldLabel>
        <AppTextInput value={nickname} onChangeText={setNickname} placeholder="For example, Moss" />
      </GlassCard>

      <GlassCard title="Growing place">
        <FieldLabel>Environment</FieldLabel>
        <ChoiceChips values={['indoor', 'outdoorContainer', 'outdoorGround']} value={environment} labels={environmentLabels} onChange={setEnvironment} />
        <FieldLabel>Light</FieldLabel>
        <ChoiceChips values={['low', 'medium', 'brightIndirect', 'direct']} value={light} labels={lightLabels} onChange={setLight} />
        <FieldLabel>Room, patio, or bed</FieldLabel>
        <AppTextInput value={locationName} onChangeText={setLocationName} placeholder="Optional" />
      </GlassCard>

      <GlassCard title="Notes">
        <AppTextInput multiline numberOfLines={4} value={notes} onChangeText={setNotes} placeholder="Anything useful about this plant" style={styles.notes} />
      </GlassCard>
      <AppButton label="Add plant" icon="plus" onPress={save} disabled={!species} />
    </ModalScaffold>
  );
}

const styles = StyleSheet.create({
  photoRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  photo: { width: 78, height: 78, borderRadius: 22 },
  speciesGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  speciesChoice: { width: '48%', minHeight: 64, justifyContent: 'center', borderRadius: 14, borderWidth: 1, padding: 10 },
  speciesName: { fontWeight: '800' },
  speciesLatin: { fontSize: 11, fontStyle: 'italic', marginTop: 2 },
  notes: { minHeight: 100, textAlignVertical: 'top' },
});
