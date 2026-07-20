import { useRouter } from 'expo-router';
import React from 'react';
import { Text } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { ChoiceChips, DemoBadge, FieldLabel } from '@/components/FormControls';
import { GlassCard } from '@/components/GlassCard';
import { ModalScaffold } from '@/components/ModalScaffold';
import { ColorMode } from '@/domain/types';
import { confirmAction } from '@/domain/confirm';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

const colorLabels: Record<ColorMode, string> = { system: 'System', light: 'Light', dark: 'Dark' };

export default function DemoSettingsScreen() {
  const { state, setColorMode, setOnboarding, resetSamples, clearAll } = usePlantStore();
  const theme = usePlantTheme();
  const router = useRouter();

  const restore = () => confirmAction('Restore sample collection?', 'Your mock changes will be replaced with the original sample plants.', 'Restore', () => { resetSamples(); router.dismissAll(); router.replace('/today'); });
  const clear = () => confirmAction('Clear all mock data?', 'This removes every plant and care event from this preview.', 'Clear all', () => { clearAll(); router.dismissAll(); router.replace('/today'); }, true);

  return (
    <ModalScaffold title="Demo Settings">
      <DemoBadge />
      <GlassCard title="Appearance">
        <FieldLabel>Color mode</FieldLabel>
        <ChoiceChips values={['system', 'light', 'dark']} value={state.colorMode} labels={colorLabels} onChange={setColorMode} />
      </GlassCard>
      <GlassCard title="Preview states">
        <Text style={{ color: theme.colors.secondaryText }}>Use these controls to test populated, empty, and first-run experiences without clearing device storage manually.</Text>
        <AppButton label="Restore sample collection" icon="restore" kind="secondary" onPress={restore} />
        <AppButton label="Clear plants and history" icon="delete-sweep-outline" kind="danger" onPress={clear} />
        <AppButton label="Replay onboarding" icon="play-circle-outline" kind="secondary" onPress={() => { router.dismissAll(); setOnboarding(false); }} />
      </GlassCard>
      <GlassCard title="About this build">
        <Text style={{ color: theme.colors.text }}>Plant Companion React Mockup 0.1</Text>
        <Text style={{ color: theme.colors.secondaryText }}>Scanner and companion output are deterministic demos. Plant and care changes persist locally in this browser or Expo installation.</Text>
      </GlassCard>
    </ModalScaffold>
  );
}
