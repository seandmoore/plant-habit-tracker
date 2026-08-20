import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { space } from './theme';
import { useTheme } from './ThemeProvider';

/** A labelled care fact, combined into one announcement for screen readers. */
export function FactRow({ icon, label, value }: { icon: string; label: string; value: string }) {
  const theme = useTheme();
  return (
    <View accessible accessibilityLabel={`${label}: ${value}`} style={styles.row}>
      <MaterialCommunityIcons name={icon as never} size={22} color={theme.colors.accent} />
      <View style={styles.text}>
        <Text style={[styles.label, { color: theme.colors.text }]}>{label}</Text>
        <Text style={{ color: theme.colors.secondaryText }}>{value}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'flex-start', gap: space.md },
  text: { flex: 1, gap: 2 },
  label: { fontWeight: '800' },
});
