import { LinearGradient } from 'expo-linear-gradient';
import React from 'react';
import type { PropsWithChildren, ReactNode } from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { space } from './theme';
import { useTheme } from './ThemeProvider';

/** A full-height tab screen: gradient ground, a heading block, then content. */
export function Screen({
  children,
  title,
  subtitle,
  action,
  scroll = true,
}: PropsWithChildren<{ title: string; subtitle?: string; action?: ReactNode; scroll?: boolean }>) {
  const theme = useTheme();

  const body = (
    <View style={styles.content}>
      <View style={styles.header}>
        <View style={styles.heading}>
          <Text accessibilityRole="header" style={[styles.title, { color: theme.colors.text }]}>{title}</Text>
          {subtitle ? <Text style={[styles.subtitle, { color: theme.colors.secondaryText }]}>{subtitle}</Text> : null}
        </View>
        {action}
      </View>
      {children}
    </View>
  );

  return (
    <LinearGradient colors={[theme.colors.background, theme.colors.backgroundEnd]} style={styles.fill}>
      <SafeAreaView style={styles.fill} edges={['top']}>
        {scroll
          ? <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">{body}</ScrollView>
          : body}
      </SafeAreaView>
    </LinearGradient>
  );
}

export function LoadingScreen() {
  const theme = useTheme();
  return (
    <View style={[styles.loading, { backgroundColor: theme.colors.background }]}>
      <ActivityIndicator size="large" color={theme.colors.accent} />
      <Text style={{ color: theme.colors.secondaryText }}>Growing your preview…</Text>
    </View>
  );
}

/** The shared empty state, so every "nothing here yet" screen reads the same way. */
export function EmptyState({ icon, title, message, action }: { icon: ReactNode; title: string; message: string; action?: ReactNode }) {
  const theme = useTheme();
  return (
    <View style={styles.empty}>
      {icon}
      <Text style={[styles.emptyTitle, { color: theme.colors.text }]}>{title}</Text>
      <Text style={[styles.emptyMessage, { color: theme.colors.secondaryText }]}>{message}</Text>
      {action}
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1 },
  content: {
    width: '100%',
    maxWidth: 820,
    alignSelf: 'center',
    padding: space.xl - 4,
    // Clears the floating companion ring and the bottom tab bar.
    paddingBottom: 112,
    gap: space.lg,
  },
  header: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: space.lg },
  heading: { flex: 1, gap: space.xs + 1 },
  title: { fontSize: 34, lineHeight: 40, fontWeight: '800', letterSpacing: -1.1 },
  subtitle: { fontSize: 17, lineHeight: 24 },
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: space.md + 2 },
  empty: { alignItems: 'center', gap: space.md, paddingVertical: space.md },
  emptyTitle: { fontSize: 21, fontWeight: '800', textAlign: 'center' },
  emptyMessage: { textAlign: 'center', lineHeight: 21 },
});
