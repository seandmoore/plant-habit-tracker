import React from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { usePlantTheme } from '@/theme/ThemeProvider';

export function LoadingGate() {
  const theme = usePlantTheme();
  return (
    <View style={[styles.root, { backgroundColor: theme.colors.background }]}>
      <ActivityIndicator size="large" color={theme.colors.accent} />
      <Text style={{ color: theme.colors.secondaryText }}>Growing your preview…</Text>
    </View>
  );
}

const styles = StyleSheet.create({ root: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 14 } });
