import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import React from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { LoadingGate } from '@/components/LoadingGate';
import { Onboarding } from '@/components/Onboarding';
import { PlantStoreProvider, usePlantStore } from '@/store/PlantStore';
import { ThemeProvider, usePlantTheme } from '@/theme/ThemeProvider';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <PlantStoreProvider>
        <ThemeProvider><RootGate /></ThemeProvider>
      </PlantStoreProvider>
    </SafeAreaProvider>
  );
}

function RootGate() {
  const { state } = usePlantStore();
  const theme = usePlantTheme();
  if (!state.hydrated) return <LoadingGate />;
  if (!state.hasCompletedOnboarding) return <Onboarding />;
  return (
    <>
      <StatusBar style={theme.dark ? 'light' : 'dark'} />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: theme.colors.background } }}>
        <Stack.Screen name="(main)" />
        <Stack.Screen name="plant/[id]" />
        <Stack.Screen name="add-plant" options={{ presentation: 'modal' }} />
        <Stack.Screen name="edit-plant" options={{ presentation: 'modal' }} />
        <Stack.Screen name="log-watering" options={{ presentation: 'modal' }} />
        <Stack.Screen name="companion" options={{ presentation: 'modal' }} />
        <Stack.Screen name="demo-settings" options={{ presentation: 'modal' }} />
      </Stack>
    </>
  );
}
