import { LinearGradient } from 'expo-linear-gradient';
import React, { PropsWithChildren, ReactNode } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { usePlantTheme } from '@/theme/ThemeProvider';

interface ScreenProps extends PropsWithChildren {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  scroll?: boolean;
}

export function Screen({ children, title, subtitle, action, scroll = true }: ScreenProps) {
  const theme = usePlantTheme();
  const content = (
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
        {scroll ? <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">{content}</ScrollView> : content}
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1 },
  content: { width: '100%', maxWidth: 820, alignSelf: 'center', padding: 20, paddingBottom: 112, gap: 18 },
  header: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: 16 },
  heading: { flex: 1, gap: 5 },
  title: { fontSize: 34, lineHeight: 40, fontWeight: '800', letterSpacing: -1.1 },
  subtitle: { fontSize: 17, lineHeight: 24 },
});
