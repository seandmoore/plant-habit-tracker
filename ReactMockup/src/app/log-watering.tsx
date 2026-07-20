import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Platform, StyleSheet, Text } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { AppTextInput, ChoiceChips, FieldLabel } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { ModalScaffold } from '@/components/ModalScaffold';
import { WaterUnit } from '@/domain/types';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

const unitLabels: Record<WaterUnit, string> = { 'mL': 'mL', 'fl oz': 'fl oz' };

export default function LogWateringScreen() {
  const { plantId } = useLocalSearchParams<{ plantId: string }>();
  const { state, logWatering } = usePlantStore();
  const plant = state.plants.find((item) => item.id === plantId);
  const [amount, setAmount] = useState('');
  const [unit, setUnit] = useState<WaterUnit>(Platform.select<WaterUnit>({ ios: 'fl oz', default: 'mL' }) ?? 'mL');
  const [note, setNote] = useState('');
  const theme = usePlantTheme();
  const router = useRouter();

  if (!plant) return <ModalScaffold title="Log Watering"><Text style={{ color: theme.colors.secondaryText }}>This plant is unavailable.</Text></ModalScaffold>;
  const save = () => {
    const parsed = Number.parseFloat(amount.replace(',', '.'));
    logWatering(plant.id, { amount: Number.isFinite(parsed) ? parsed : undefined, waterUnit: unit, note });
    router.back();
  };

  return (
    <ModalScaffold title={`Water ${plant.nickname}`}>
      <GlassCard title="Watering">
        <FieldLabel>Amount (optional)</FieldLabel>
        <AppTextInput keyboardType="decimal-pad" value={amount} onChangeText={setAmount} placeholder="For example, 250" />
        <ChoiceChips values={['mL', 'fl oz']} value={unit} labels={unitLabels} onChange={setUnit} />
        <FieldLabel>Observation or note</FieldLabel>
        <AppTextInput multiline value={note} onChangeText={setNote} placeholder="How did the soil and plant look?" style={styles.notes} />
      </GlassCard>
      <AppButton label="Save watering" icon="water" onPress={save} />
    </ModalScaffold>
  );
}

const styles = StyleSheet.create({ notes: { minHeight: 100, textAlignVertical: 'top' } });
