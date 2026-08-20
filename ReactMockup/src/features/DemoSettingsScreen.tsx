import { useRouter } from 'expo-router';
import React from 'react';
import { Text } from 'react-native';
import { catalogVersion } from '@/data/catalog';
import type { ColorMode } from '@/domain/types';
import { usePlantStore } from '@/state/PlantStore';
import { Button, Card, ChoiceChips, confirmAction, DemoBadge, FieldLabel, ModalScreen, useTheme } from '@/ui';

const colorLabels: Record<ColorMode, string> = { system: 'System', light: 'Light', dark: 'Dark' };
const colorOrder: ColorMode[] = ['system', 'light', 'dark'];

export function DemoSettingsScreen() {
  const { state, setColorMode, setOnboarding, restoreSamples, clearCollection } = usePlantStore();
  const theme = useTheme();
  const router = useRouter();

  const restore = () => confirmAction(
    'Restore sample collection?',
    'Your mock changes will be replaced with the original sample plants.',
    'Restore',
    () => {
      restoreSamples();
      router.dismissAll();
      router.replace('/today');
    },
  );

  const clear = () => confirmAction(
    'Clear all mock data?',
    'This removes every plant and care event from this preview.',
    'Clear all',
    () => {
      clearCollection();
      router.dismissAll();
      router.replace('/today');
    },
    true,
  );

  return (
    <ModalScreen title="Demo Settings">
      <DemoBadge />

      <Card title="Appearance">
        <FieldLabel>Color mode</FieldLabel>
        <ChoiceChips values={colorOrder} value={state.colorMode} labels={colorLabels} onChange={setColorMode} />
      </Card>

      <Card title="Preview states">
        <Text style={{ color: theme.colors.secondaryText }}>
          Use these controls to test populated, empty, and first-run experiences without clearing device
          storage manually.
        </Text>
        <Button label="Restore sample collection" icon="restore" kind="secondary" onPress={restore} />
        <Button label="Clear plants and history" icon="delete-sweep-outline" kind="danger" onPress={clear} />
        <Button
          label="Replay onboarding"
          icon="play-circle-outline"
          kind="secondary"
          onPress={() => { router.dismissAll(); setOnboarding(false); }}
        />
      </Card>

      <Card title="About this build">
        <Text style={{ color: theme.colors.text }}>Plant Companion React Mockup 0.1</Text>
        <Text style={{ color: theme.colors.secondaryText }}>
          Catalog contract v{catalogVersion}. Scanner and companion output are deterministic demos. Plant and
          care changes persist locally in this browser or Expo installation.
        </Text>
      </Card>
    </ModalScreen>
  );
}
