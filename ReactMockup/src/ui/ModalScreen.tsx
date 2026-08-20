import { MaterialCommunityIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import React from 'react';
import type { PropsWithChildren, ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { minTapTarget, space } from './theme';
import { useTheme } from './ThemeProvider';

/** A presented screen with a close affordance; used for details, forms, and the companion. */
export function ModalScreen({
  title,
  children,
  action,
  scroll = true,
}: PropsWithChildren<{ title: string; action?: ReactNode; scroll?: boolean }>) {
  const theme = useTheme();
  const router = useRouter();
  const body = <View style={styles.content}>{children}</View>;

  return (
    <LinearGradient colors={[theme.colors.background, theme.colors.backgroundEnd]} style={styles.fill}>
      <SafeAreaView style={styles.fill}>
        <View style={[styles.header, { borderColor: theme.colors.border }]}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Close"
            hitSlop={10}
            onPress={() => (router.canGoBack() ? router.back() : router.replace('/today'))}
            style={styles.close}
          >
            <MaterialCommunityIcons name="close" size={24} color={theme.colors.text} />
          </Pressable>
          <Text accessibilityRole="header" numberOfLines={1} style={[styles.title, { color: theme.colors.text }]}>
            {title}
          </Text>
          <View style={styles.action}>{action}</View>
        </View>
        {scroll
          ? <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">{body}</ScrollView>
          : body}
      </SafeAreaView>
    </LinearGradient>
  );
}

/** Shown when a modal is opened for a plant or species that no longer exists. */
export function MissingRecord({ title, message }: { title: string; message: string }) {
  const theme = useTheme();
  return (
    <ModalScreen title={title}>
      <Text style={{ color: theme.colors.secondaryText }}>{message}</Text>
    </ModalScreen>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: {
    minHeight: 58,
    borderBottomWidth: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: space.lg - 2,
  },
  close: { width: minTapTarget, height: minTapTarget, alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1, textAlign: 'center', fontSize: 18, fontWeight: '800' },
  action: { minWidth: minTapTarget, alignItems: 'flex-end' },
  scroll: { flexGrow: 1 },
  content: {
    width: '100%',
    maxWidth: 700,
    alignSelf: 'center',
    padding: space.xl - 4,
    paddingBottom: 50,
    gap: space.lg,
  },
});
