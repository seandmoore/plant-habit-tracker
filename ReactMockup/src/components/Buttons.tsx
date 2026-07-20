import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, ViewStyle } from 'react-native';
import { usePlantTheme } from '@/theme/ThemeProvider';

interface AppButtonProps {
  label: string;
  icon?: string;
  onPress(): void;
  kind?: 'primary' | 'secondary' | 'danger' | 'plain';
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
}

export function AppButton({ label, icon, onPress, kind = 'primary', disabled, loading, style }: AppButtonProps) {
  const theme = usePlantTheme();
  const backgroundColor = kind === 'primary' ? theme.colors.accent : kind === 'danger' ? `${theme.colors.danger}1F` : kind === 'plain' ? 'transparent' : theme.colors.surfaceStrong;
  const color = kind === 'primary' ? '#FFFFFF' : kind === 'danger' ? theme.colors.danger : theme.colors.text;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      disabled={disabled || loading}
      onPress={onPress}
      style={({ pressed }) => [styles.button, { backgroundColor, borderColor: theme.colors.border, opacity: disabled ? 0.45 : pressed ? 0.72 : 1 }, style]}
    >
      {loading ? <ActivityIndicator color={color} /> : icon ? <MaterialCommunityIcons name={icon as never} size={18} color={color} /> : null}
      <Text style={[styles.label, { color }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: { minHeight: 46, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, borderRadius: 16, borderWidth: 1, paddingHorizontal: 16, paddingVertical: 10 },
  label: { fontSize: 15, fontWeight: '700' },
});
