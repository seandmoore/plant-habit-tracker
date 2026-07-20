import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { PropsWithChildren, ReactNode } from 'react';
import { LinearGradient } from 'expo-linear-gradient';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { usePlantTheme } from '@/theme/ThemeProvider';

export function ModalScaffold({ title, children, action, scroll = true }: PropsWithChildren<{ title: string; action?: ReactNode; scroll?: boolean }>) {
  const theme = usePlantTheme();
  const router = useRouter();
  const body = <View style={styles.content}>{children}</View>;
  return (
    <LinearGradient colors={[theme.colors.background, theme.colors.backgroundEnd]} style={styles.fill}>
      <SafeAreaView style={styles.fill}>
        <View style={[styles.header, { borderColor: theme.colors.border }]}>
          <Pressable accessibilityRole="button" accessibilityLabel="Close" hitSlop={10} onPress={() => router.back()} style={styles.close}>
            <MaterialCommunityIcons name="close" size={24} color={theme.colors.text} />
          </Pressable>
          <Text accessibilityRole="header" numberOfLines={1} style={[styles.title, { color: theme.colors.text }]}>{title}</Text>
          <View style={styles.action}>{action}</View>
        </View>
        {scroll ? <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">{body}</ScrollView> : body}
      </SafeAreaView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: { minHeight: 58, borderBottomWidth: 1, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16 },
  close: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1, textAlign: 'center', fontSize: 18, fontWeight: '800' },
  action: { width: 44, alignItems: 'flex-end' },
  scroll: { flexGrow: 1 },
  content: { width: '100%', maxWidth: 700, alignSelf: 'center', padding: 20, paddingBottom: 50, gap: 18 },
});
