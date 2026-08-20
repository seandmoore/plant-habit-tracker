import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import React from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { PlantStoreProvider, usePlantStore } from '@/state/PlantStore';
import { LoadingScreen, ThemeProvider, useTheme } from '@/ui';
import { Onboarding } from '@/features/Onboarding';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <PlantStoreProvider>
        <ThemeProvider>
          <RootGate />
        </ThemeProvider>
      </PlantStoreProvider>
    </SafeAreaProvider>
  );
}

/**
 * Storage is read before anything renders, so a returning visitor never sees the sample
 * collection flash over their own plants, and onboarding gates the navigator entirely.
 */
function RootGate() {
  const { state } = usePlantStore();
  const theme = useTheme();

  if (!state.hydrated) return <LoadingScreen />;
  if (!state.hasCompletedOnboarding) return <Onboarding />;

  return (
    <>
      <StatusBar style={theme.dark ? 'light' : 'dark'} />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: theme.colors.background } }}>
        <Stack.Screen name="(main)" />
        <Stack.Screen name="plant/[id]" />
        <Stack.Screen name="species/[id]" options={{ presentation: 'modal' }} />
        <Stack.Screen name="add-plant" options={{ presentation: 'modal' }} />
        <Stack.Screen name="edit-plant" options={{ presentation: 'modal' }} />
        <Stack.Screen name="log-watering" options={{ presentation: 'modal' }} />
        <Stack.Screen name="companion" options={{ presentation: 'modal' }} />
        <Stack.Screen name="demo-settings" options={{ presentation: 'modal' }} />
      </Stack>
    </>
  );
}
