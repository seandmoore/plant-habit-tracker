import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Href, Slot, usePathname, useRouter } from 'expo-router';
import React, { PropsWithChildren } from 'react';
import { Platform, Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { usePlantTheme } from '@/theme/ThemeProvider';
import { CompanionRing } from './CompanionRing';

const navItems = [
  { path: '/today', label: 'Today', icon: 'weather-sunny' },
  { path: '/plants', label: 'My Plants', icon: 'leaf' },
  { path: '/scan', label: 'Scan', icon: 'line-scan' },
  { path: '/discover', label: 'Discover', icon: 'magnify' },
] as const;

export function AppChrome({ children }: PropsWithChildren) {
  const { width } = useWindowDimensions();
  const wide = width >= 900;
  const theme = usePlantTheme();
  const router = useRouter();
  const pathname = usePathname();
  const content = children ?? <Slot />;

  return (
    <View style={[styles.root, { backgroundColor: theme.colors.background }]}>
      {wide ? (
        <SafeAreaView style={[styles.sidebar, { backgroundColor: theme.colors.tab, borderColor: theme.colors.border }]}>
          <View style={styles.brand}>
            <View style={[styles.brandIcon, { backgroundColor: theme.colors.mint }]}><MaterialCommunityIcons name="sprout" size={25} color={theme.colors.accentStrong} /></View>
            <View><Text style={[styles.brandTitle, { color: theme.colors.text }]}>Plant Companion</Text><Text style={[styles.demoLabel, { color: theme.colors.secondaryText }]}>INTERACTIVE MOCKUP</Text></View>
          </View>
          <View style={styles.navList}>{navItems.map((item) => <NavButton key={item.path} {...item} active={pathname.startsWith(item.path)} onPress={() => router.replace(item.path as Href)} />)}</View>
          <View style={styles.sidebarFooter}>
            <NavButton path="/demo-settings" label="Demo settings" icon="tune-variant" active={pathname === '/demo-settings'} onPress={() => router.push('/demo-settings' as Href)} />
          </View>
        </SafeAreaView>
      ) : null}

      <View style={styles.content}>{content}</View>

      {!wide ? (
        <SafeAreaView edges={['bottom']} style={[styles.bottomBar, { backgroundColor: theme.colors.tab, borderColor: theme.colors.border }]}>
          {navItems.map((item) => <NavButton key={item.path} {...item} compact active={pathname.startsWith(item.path)} onPress={() => router.replace(item.path as Href)} />)}
        </SafeAreaView>
      ) : null}

      <View style={[styles.floating, { bottom: wide ? 24 : Platform.OS === 'web' ? 92 : 100 }]}>
        <Pressable accessibilityRole="button" accessibilityLabel="Demo settings" onPress={() => router.push('/demo-settings' as Href)} style={[styles.settingsButton, { backgroundColor: theme.colors.surfaceStrong, borderColor: theme.colors.border }]}>
          <MaterialCommunityIcons name="tune-variant" size={21} color={theme.colors.text} />
        </Pressable>
        <CompanionRing onPress={() => router.push('/companion' as Href)} />
      </View>
    </View>
  );
}

interface NavButtonProps {
  path: string;
  label: string;
  icon: string;
  active: boolean;
  compact?: boolean;
  onPress(): void;
}

function NavButton({ label, icon, active, compact, onPress }: NavButtonProps) {
  const theme = usePlantTheme();
  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityState={{ selected: active }}
      onPress={onPress}
      style={[compact ? styles.compactNav : styles.navButton, active && { backgroundColor: `${theme.colors.accent}20` }]}
    >
      <MaterialCommunityIcons name={icon as never} size={compact ? 23 : 21} color={active ? theme.colors.accent : theme.colors.secondaryText} />
      <Text numberOfLines={1} style={[compact ? styles.compactLabel : styles.navLabel, { color: active ? theme.colors.accent : theme.colors.secondaryText }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, flexDirection: 'row' },
  content: { flex: 1 },
  sidebar: { width: 250, borderRightWidth: 1, padding: 18 },
  brand: { flexDirection: 'row', alignItems: 'center', gap: 12, marginVertical: 14, marginBottom: 32 },
  brandIcon: { width: 44, height: 44, borderRadius: 15, alignItems: 'center', justifyContent: 'center' },
  brandTitle: { fontSize: 18, fontWeight: '800' },
  demoLabel: { fontSize: 9, fontWeight: '800', letterSpacing: 1.1, marginTop: 2 },
  navList: { gap: 7 },
  navButton: { minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 12, borderRadius: 15, paddingHorizontal: 14 },
  navLabel: { fontSize: 15, fontWeight: '700' },
  sidebarFooter: { marginTop: 'auto' },
  bottomBar: { position: 'absolute', left: 0, right: 0, bottom: 0, minHeight: 72, borderTopWidth: 1, flexDirection: 'row', justifyContent: 'space-around', paddingTop: 8 },
  compactNav: { flex: 1, minHeight: 54, alignItems: 'center', justifyContent: 'center', gap: 3, paddingHorizontal: 2 },
  compactLabel: { fontSize: 10, fontWeight: '700' },
  floating: { position: 'absolute', right: 20, flexDirection: 'row', alignItems: 'center', gap: 10 },
  settingsButton: { width: 44, height: 44, borderRadius: 22, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
});
