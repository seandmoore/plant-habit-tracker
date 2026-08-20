import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';
import type { StyleProp, ViewStyle } from 'react-native';
import { minTapTarget, radius, space, tint } from './theme';
import { useTheme } from './ThemeProvider';
import type { Theme } from './theme';

export type ButtonKind = 'primary' | 'secondary' | 'danger' | 'plain';

interface ButtonProps {
  label: string;
  onPress(): void;
  icon?: string;
  kind?: ButtonKind;
  disabled?: boolean;
  loading?: boolean;
  style?: StyleProp<ViewStyle>;
}

const paletteFor = (theme: Theme, kind: ButtonKind) => {
  switch (kind) {
    case 'primary':
      return { background: theme.colors.accent, foreground: theme.colors.onAccent };
    case 'danger':
      return { background: tint(theme.colors.danger), foreground: theme.colors.danger };
    case 'plain':
      return { background: 'transparent', foreground: theme.colors.text };
    default:
      return { background: theme.colors.surfaceStrong, foreground: theme.colors.text };
  }
};

export function Button({ label, onPress, icon, kind = 'primary', disabled, loading, style }: ButtonProps) {
  const theme = useTheme();
  const { background, foreground } = paletteFor(theme, kind);
  const inactive = disabled || loading;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled: Boolean(inactive), busy: Boolean(loading) }}
      disabled={inactive}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: background, borderColor: theme.colors.border, opacity: disabled ? 0.45 : pressed ? 0.72 : 1 },
        style,
      ]}
    >
      {loading
        ? <ActivityIndicator color={foreground} />
        : icon ? <MaterialCommunityIcons name={icon as never} size={18} color={foreground} /> : null}
      <Text style={[styles.label, { color: foreground }]}>{label}</Text>
    </Pressable>
  );
}

/** A round icon-only control; the label is carried by the accessibility name. */
export function IconButton({ icon, label, onPress, tone }: { icon: string; label: string; onPress(): void; tone?: 'accent' | 'surface' }) {
  const theme = useTheme();
  const onAccent = tone === 'accent';

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ pressed }) => [
        styles.iconButton,
        {
          backgroundColor: onAccent ? theme.colors.accent : theme.colors.surfaceStrong,
          borderColor: theme.colors.border,
          opacity: pressed ? 0.72 : 1,
        },
      ]}
    >
      <MaterialCommunityIcons name={icon as never} size={21} color={onAccent ? theme.colors.onAccent : theme.colors.text} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: minTapTarget,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: space.sm,
    borderRadius: radius.md,
    borderWidth: 1,
    paddingHorizontal: space.lg,
    paddingVertical: 10,
  },
  label: { fontSize: 15, fontWeight: '700' },
  iconButton: {
    width: minTapTarget,
    height: minTapTarget,
    borderRadius: radius.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
