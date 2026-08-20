import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Slot, usePathname, useRouter } from 'expo-router';
import type { Href } from 'expo-router';
import React from 'react';
import { Platform, Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CompanionRing, radius, space, tint, useTheme } from '@/ui';

interface NavItem {
  path: Href;
  label: string;
  icon: string;
}

const navItems: NavItem[] = [
  { path: '/today', label: 'Today', icon: 'weather-sunny' },
  { path: '/plants', label: 'My Plants', icon: 'leaf' },
  { path: '/scan', label: 'Scan', icon: 'line-scan' },
  { path: '/discover', label: 'Discover', icon: 'magnify' },
];

/** Wide viewports get a sidebar, narrow ones a bottom bar. Both drive the same routes. */
const WIDE_BREAKPOINT = 900;

export function AppChrome() {
  const { width } = useWindowDimensions();
  const theme = useTheme();
  const router = useRouter();
  const pathname = usePathname();
  const wide = width >= WIDE_BREAKPOINT;

  const isActive = (path: Href) => pathname.startsWith(String(path));

  return (
    <View style={[styles.root, { backgroundColor: theme.colors.background }]}>
      {wide ? (
        <SafeAreaView style={[styles.sidebar, { backgroundColor: theme.colors.chrome, borderColor: theme.colors.border }]}>
          <View style={styles.brand}>
            <View style={[styles.brandIcon, { backgroundColor: theme.colors.mint }]}>
              <MaterialCommunityIcons name="sprout" size={25} color={theme.colors.accentStrong} />
            </View>
            <View>
              <Text style={[styles.brandTitle, { color: theme.colors.text }]}>Plant Companion</Text>
              <Text style={[styles.brandLabel, { color: theme.colors.secondaryText }]}>INTERACTIVE MOCKUP</Text>
            </View>
          </View>

          <View style={styles.navList}>
            {navItems.map((item) => (
              <NavButton key={String(item.path)} {...item} active={isActive(item.path)} onPress={() => router.replace(item.path)} />
            ))}
          </View>

          <View style={styles.sidebarFooter}>
            <NavButton
              path="/demo-settings"
              label="Demo settings"
              icon="tune-variant"
              active={pathname === '/demo-settings'}
              onPress={() => router.push('/demo-settings')}
            />
          </View>
        </SafeAreaView>
      ) : null}

      <View style={styles.content}><Slot /></View>

      {!wide ? (
        <SafeAreaView edges={['bottom']} style={[styles.bottomBar, { backgroundColor: theme.colors.chrome, borderColor: theme.colors.border }]}>
          {navItems.map((item) => (
            <NavButton key={String(item.path)} {...item} compact active={isActive(item.path)} onPress={() => router.replace(item.path)} />
          ))}
        </SafeAreaView>
      ) : null}

      <View style={[styles.floating, { bottom: wide ? space.xl : Platform.OS === 'web' ? 92 : 100 }]}>
        {!wide ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Demo settings"
            onPress={() => router.push('/demo-settings')}
            style={[styles.settingsButton, { backgroundColor: theme.colors.surfaceStrong, borderColor: theme.colors.border }]}
          >
            <MaterialCommunityIcons name="tune-variant" size={21} color={theme.colors.text} />
          </Pressable>
        ) : null}
        <CompanionRing onPress={() => router.push('/companion')} />
      </View>
    </View>
  );
}

function NavButton({
  label,
  icon,
  active,
  compact,
  onPress,
}: NavItem & { active: boolean; compact?: boolean; onPress(): void }) {
  const theme = useTheme();
  const color = active ? theme.colors.accent : theme.colors.secondaryText;

  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityState={{ selected: active }}
      accessibilityLabel={label}
      onPress={onPress}
      style={[compact ? styles.compactNav : styles.navButton, active && { backgroundColor: tint(theme.colors.accent, '20') }]}
    >
      <MaterialCommunityIcons name={icon as never} size={compact ? 23 : 21} color={color} />
      <Text numberOfLines={1} style={[compact ? styles.compactLabel : styles.navLabel, { color }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, flexDirection: 'row' },
  content: { flex: 1 },
  sidebar: { width: 250, borderRightWidth: 1, padding: space.lg },
  brand: { flexDirection: 'row', alignItems: 'center', gap: space.md, marginVertical: space.md + 2, marginBottom: space.xxl },
  brandIcon: { width: 44, height: 44, borderRadius: 15, alignItems: 'center', justifyContent: 'center' },
  brandTitle: { fontSize: 18, fontWeight: '800' },
  brandLabel: { fontSize: 9, fontWeight: '800', letterSpacing: 1.1, marginTop: 2 },
  navList: { gap: 7 },
  navButton: { minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: space.md, borderRadius: radius.sm + 1, paddingHorizontal: space.md + 2 },
  navLabel: { fontSize: 15, fontWeight: '700' },
  sidebarFooter: { marginTop: 'auto' },
  bottomBar: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    minHeight: 72,
    borderTopWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingTop: space.sm,
  },
  compactNav: { flex: 1, minHeight: 54, alignItems: 'center', justifyContent: 'center', gap: 3, paddingHorizontal: 2 },
  compactLabel: { fontSize: 10, fontWeight: '700' },
  floating: { position: 'absolute', right: space.xl - 4, flexDirection: 'row', alignItems: 'center', gap: space.sm + 2 },
  settingsButton: { width: 44, height: 44, borderRadius: 22, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
});
