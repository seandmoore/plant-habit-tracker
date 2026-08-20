import { BlurView } from 'expo-blur';
import React from 'react';
import type { PropsWithChildren } from 'react';
import { Platform, StyleSheet, Text, View } from 'react-native';
import type { StyleProp, ViewStyle } from 'react-native';
import { radius, space } from './theme';
import { useTheme } from './ThemeProvider';

/** The app's one content container. Blur is native-only; the web falls back to the tint. */
export function Card({ children, title, style }: PropsWithChildren<{ title?: string; style?: StyleProp<ViewStyle> }>) {
  const theme = useTheme();

  return (
    <View style={[styles.card, { backgroundColor: theme.colors.surface, borderColor: theme.colors.border, shadowColor: theme.colors.shadow }, style]}>
      {Platform.OS !== 'web' && <BlurView intensity={32} tint={theme.dark ? 'dark' : 'light'} style={StyleSheet.absoluteFill} />}
      <View style={styles.content}>
        {title ? <Text accessibilityRole="header" style={[styles.title, { color: theme.colors.text }]}>{title}</Text> : null}
        {children}
      </View>
    </View>
  );
}

/** A hairline used between rows inside a card; skipped above the first row. */
export function RowDivider({ index }: { index: number }) {
  const theme = useTheme();
  if (index === 0) return null;
  return <View style={[styles.divider, { backgroundColor: theme.colors.border }]} />;
}

const styles = StyleSheet.create({
  card: {
    borderRadius: radius.lg,
    borderWidth: 1,
    overflow: 'hidden',
    shadowOpacity: 1,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 6 },
    elevation: 3,
  },
  content: { padding: space.lg, gap: space.md },
  title: { fontSize: 20, fontWeight: '700', letterSpacing: -0.3 },
  divider: { height: 1, marginVertical: space.xs },
});
