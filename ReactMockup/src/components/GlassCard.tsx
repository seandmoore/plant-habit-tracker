import { BlurView } from 'expo-blur';
import React, { PropsWithChildren } from 'react';
import { Platform, StyleProp, StyleSheet, Text, View, ViewStyle } from 'react-native';
import { usePlantTheme } from '@/theme/ThemeProvider';

interface GlassCardProps extends PropsWithChildren {
  title?: string;
  style?: StyleProp<ViewStyle>;
}

export function GlassCard({ children, title, style }: GlassCardProps) {
  const theme = usePlantTheme();
  return (
    <View style={[styles.card, { backgroundColor: theme.colors.surface, borderColor: theme.colors.border, shadowColor: theme.colors.shadow }, style]}>
      {Platform.OS !== 'web' && <BlurView intensity={32} tint={theme.dark ? 'dark' : 'light'} style={StyleSheet.absoluteFill} />}
      <View style={styles.content}>
        {title ? <Text style={[styles.title, { color: theme.colors.text }]}>{title}</Text> : null}
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 24, borderWidth: 1, overflow: 'hidden', shadowOpacity: 1, shadowRadius: 16,
    shadowOffset: { width: 0, height: 6 }, elevation: 3,
  },
  content: { padding: 18, gap: 12 },
  title: { fontSize: 20, fontWeight: '700', letterSpacing: -0.3 },
});
