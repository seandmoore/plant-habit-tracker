import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Platform } from 'react-native';
import { waterUnitLabels, waterUnitOrder } from '@/domain/labels';
import { parseAmount } from '@/domain/parse';
import type { WaterUnit } from '@/domain/types';
import { usePlantStore } from '@/state/PlantStore';
import { usePlant } from '@/state/selectors';
import { Button, Card, ChoiceChips, FieldLabel, Hint, MissingRecord, ModalScreen, TextField } from '@/ui';

/** Matches the unit people are most likely to reach for on each platform. */
const defaultUnit = (): WaterUnit => Platform.select<WaterUnit>({ ios: 'fl oz', default: 'mL' }) ?? 'mL';

export function LogWateringScreen() {
  const { plantId } = useLocalSearchParams<{ plantId: string }>();
  const plant = usePlant(plantId);
  const { logWatering } = usePlantStore();
  const router = useRouter();

  const [amount, setAmount] = useState('');
  const [unit, setUnit] = useState<WaterUnit>(defaultUnit);
  const [note, setNote] = useState('');

  if (!plant) {
    return <MissingRecord title="Log Watering" message="This plant is unavailable." />;
  }

  const save = () => {
    logWatering(plant.id, { amount: parseAmount(amount), waterUnit: unit, note });
    router.back();
  };

  return (
    <ModalScreen title={`Water ${plant.nickname}`}>
      <Card title="Watering">
        <FieldLabel>Amount (optional)</FieldLabel>
        <TextField
          keyboardType="decimal-pad"
          value={amount}
          onChangeText={setAmount}
          placeholder="For example, 250"
          accessibilityLabel="Amount of water"
        />
        <ChoiceChips values={waterUnitOrder} value={unit} labels={waterUnitLabels} onChange={setUnit} />
        <Hint>Leave the amount blank to record only that you watered.</Hint>

        <FieldLabel>Observation or note</FieldLabel>
        <TextField multiline value={note} onChangeText={setNote} placeholder="How did the soil and plant look?" />
      </Card>

      <Button label="Save watering" icon="water" onPress={save} />
    </ModalScreen>
  );
}
