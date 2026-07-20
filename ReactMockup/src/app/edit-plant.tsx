import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { StyleSheet, Switch, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { AppTextInput, ChoiceChips, FieldLabel } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { ModalScaffold } from '@/components/ModalScaffold';
import { environmentLabels, lightLabels } from '@/domain/labels';
import { LightLevel, PlantEnvironment } from '@/domain/types';
import { confirmAction } from '@/domain/confirm';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

export default function EditPlantScreen() {
  const { plantId } = useLocalSearchParams<{ plantId: string }>();
  const { state, updatePlant, deletePlant } = usePlantStore();
  const plant = state.plants.find((item) => item.id === plantId);
  const [nickname, setNickname] = useState('');
  const [environment, setEnvironment] = useState<PlantEnvironment>('indoor');
  const [light, setLight] = useState<LightLevel>('brightIndirect');
  const [locationName, setLocationName] = useState('');
  const [notes, setNotes] = useState('');
  const [reminderEnabled, setReminderEnabled] = useState(false);
  const theme = usePlantTheme();
  const router = useRouter();

  useEffect(() => {
    if (!plant) return;
    setNickname(plant.nickname); setEnvironment(plant.environment); setLight(plant.light);
    setLocationName(plant.locationName); setNotes(plant.notes); setReminderEnabled(plant.reminderEnabled);
  }, [plant]);

  if (!plant) return <ModalScaffold title="Plant Details"><Text style={{ color: theme.colors.secondaryText }}>This plant is no longer available.</Text></ModalScaffold>;

  const save = () => {
    updatePlant(plant.id, { nickname: nickname.trim() || plant.commonName, environment, light, locationName: locationName.trim(), notes: notes.trim(), reminderEnabled });
    router.back();
  };
  const confirmDelete = () => confirmAction(
    `Delete ${plant.nickname}?`,
    'This permanently removes its local mock care history.',
    'Delete',
    () => { deletePlant(plant.id); router.dismissAll(); router.replace('/plants'); },
    true,
  );

  return (
    <ModalScaffold title="Plant Details">
      <GlassCard>
        <FieldLabel>Nickname</FieldLabel><AppTextInput value={nickname} onChangeText={setNickname} />
        <FieldLabel>Environment</FieldLabel><ChoiceChips values={['indoor', 'outdoorContainer', 'outdoorGround']} value={environment} labels={environmentLabels} onChange={setEnvironment} />
        <FieldLabel>Light</FieldLabel><ChoiceChips values={['low', 'medium', 'brightIndirect', 'direct']} value={light} labels={lightLabels} onChange={setLight} />
        <FieldLabel>Location</FieldLabel><AppTextInput value={locationName} onChangeText={setLocationName} placeholder="Optional" />
        <View style={styles.toggle}><Text style={[styles.toggleText, { color: theme.colors.text }]}>Remind me to check soil</Text><Switch value={reminderEnabled} onValueChange={setReminderEnabled} trackColor={{ true: theme.colors.accent }} /></View>
        <FieldLabel>Notes</FieldLabel><AppTextInput multiline value={notes} onChangeText={setNotes} style={styles.notes} />
      </GlassCard>
      <AppButton label="Save changes" onPress={save} />
      <AppButton label="Delete plant" icon="trash-can-outline" kind="danger" onPress={confirmDelete} />
    </ModalScaffold>
  );
}

const styles = StyleSheet.create({
  toggle: { minHeight: 48, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 16 },
  toggleText: { flex: 1, fontWeight: '700' },
  notes: { minHeight: 100, textAlignVertical: 'top' },
});
