import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState } from 'react';
import { environmentLabels, environmentOrder, lightLabels, lightOrder } from '@/domain/labels';
import type { LightLevel, PlantEnvironment } from '@/domain/types';
import { usePlantStore } from '@/state/PlantStore';
import { usePlant } from '@/state/selectors';
import {
  Button,
  Card,
  ChoiceChips,
  confirmAction,
  FieldLabel,
  MissingRecord,
  ModalScreen,
  TextField,
  ToggleRow,
} from '@/ui';

export function EditPlantScreen() {
  const { plantId } = useLocalSearchParams<{ plantId: string }>();
  const plant = usePlant(plantId);

  if (!plant) {
    return <MissingRecord title="Plant Details" message="This plant is no longer available." />;
  }

  // Keyed on the plant so the form state is rebuilt if the record underneath ever changes.
  return <EditPlantForm key={plant.id} plantId={plant.id} />;
}

function EditPlantForm({ plantId }: { plantId: string }) {
  const plant = usePlant(plantId);
  const { updatePlant, deletePlant } = usePlantStore();
  const router = useRouter();

  const [nickname, setNickname] = useState(plant?.nickname ?? '');
  const [environment, setEnvironment] = useState<PlantEnvironment>(plant?.environment ?? 'indoor');
  const [light, setLight] = useState<LightLevel>(plant?.light ?? 'brightIndirect');
  const [locationName, setLocationName] = useState(plant?.locationName ?? '');
  const [notes, setNotes] = useState(plant?.notes ?? '');
  const [reminderEnabled, setReminderEnabled] = useState(plant?.reminderEnabled ?? false);

  if (!plant) {
    return <MissingRecord title="Plant Details" message="This plant is no longer available." />;
  }

  const save = () => {
    updatePlant(plant.id, {
      nickname: nickname.trim() || plant.commonName,
      environment,
      light,
      locationName: locationName.trim(),
      notes: notes.trim(),
      reminderEnabled,
    });
    router.back();
  };

  const confirmDelete = () => confirmAction(
    `Delete ${plant.nickname}?`,
    'This permanently removes its local mock care history.',
    'Delete',
    () => {
      deletePlant(plant.id);
      router.dismissAll();
      router.replace('/plants');
    },
    true,
  );

  return (
    <ModalScreen title="Plant Details">
      <Card>
        <FieldLabel>Nickname</FieldLabel>
        <TextField value={nickname} onChangeText={setNickname} />
        <FieldLabel>Environment</FieldLabel>
        <ChoiceChips values={environmentOrder} value={environment} labels={environmentLabels} onChange={setEnvironment} />
        <FieldLabel>Light</FieldLabel>
        <ChoiceChips values={lightOrder} value={light} labels={lightLabels} onChange={setLight} />
        <FieldLabel>Location</FieldLabel>
        <TextField value={locationName} onChangeText={setLocationName} placeholder="Optional" />
        <ToggleRow label="Remind me to check soil" value={reminderEnabled} onChange={setReminderEnabled} />
        <FieldLabel>Notes</FieldLabel>
        <TextField multiline value={notes} onChangeText={setNotes} />
      </Card>

      <Button label="Save changes" onPress={save} />
      <Button label="Delete plant" icon="trash-can-outline" kind="danger" onPress={confirmDelete} />
    </ModalScreen>
  );
}
