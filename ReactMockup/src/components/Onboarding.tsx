import { MaterialCommunityIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';
import { AppButton } from './Buttons';
import { CompanionRing } from './CompanionRing';

const pages = [
  { icon: 'leaf', title: 'Meet your calm care companion', message: 'Keep indoor and outdoor plants together, with readable guidance grounded in what you record.' },
  { icon: 'water-percent', title: 'Observe, then water', message: 'Care dates remind you to check the soil. Quick logs reveal patterns without turning plant care into a streak.' },
  { icon: 'line-scan', title: 'Search, scan, and ask', message: 'Explore a starter catalog, try photo suggestions, and ask the companion to explain saved care information.' },
] as const;

export function Onboarding() {
  const [step, setStep] = useState(0);
  const theme = usePlantTheme();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { setOnboarding } = usePlantStore();
  const page = pages[step] ?? pages[0];

  const continueFlow = () => {
    if (step < pages.length - 1) return setStep(step + 1);
    setOnboarding(true);
    router.replace('/plants');
  };

  return (
    <LinearGradient colors={[theme.colors.background, theme.colors.backgroundEnd]} style={[styles.root, { paddingTop: insets.top + 30, paddingBottom: insets.bottom + 30 }]}>
      <View style={styles.content}>
        <CompanionRing state={step === 2 ? 'speaking' : 'idle'} onPress={() => undefined} size={82} />
        <MaterialCommunityIcons name={page.icon} size={42} color={theme.colors.accent} />
        <Text accessibilityRole="header" style={[styles.title, { color: theme.colors.text }]}>{page.title}</Text>
        <Text style={[styles.message, { color: theme.colors.secondaryText }]}>{page.message}</Text>
        <View accessibilityLabel={`Step ${step + 1} of ${pages.length}`} style={styles.dots}>
          {pages.map((_, index) => <View key={index} style={[styles.dot, { width: index === step ? 28 : 8, backgroundColor: index === step ? theme.colors.accent : theme.colors.border }]} />)}
        </View>
        <AppButton label={step === pages.length - 1 ? 'Explore my sample plants' : 'Continue'} onPress={continueFlow} style={styles.button} />
        {step > 0 ? <AppButton label="Back" kind="plain" onPress={() => setStep(step - 1)} /> : null}
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 26 },
  content: { width: '100%', maxWidth: 620, alignItems: 'center', gap: 20 },
  title: { fontSize: 34, lineHeight: 40, fontWeight: '800', letterSpacing: -1, textAlign: 'center' },
  message: { maxWidth: 520, fontSize: 18, lineHeight: 27, textAlign: 'center' },
  dots: { flexDirection: 'row', gap: 7, marginTop: 10 },
  dot: { height: 8, borderRadius: 999 },
  button: { minWidth: 230, marginTop: 8 },
});
