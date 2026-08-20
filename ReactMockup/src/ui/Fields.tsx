import React from 'react';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Switch, Text, TextInput, View } from 'react-native';
import type { TextInputProps } from 'react-native';
import { minTapTarget, radius, space, tint } from './theme';
import { useTheme } from './ThemeProvider';

export function FieldLabel({ children }: { children: ReactNode }) {
  const theme = useTheme();
  return <Text style={[styles.label, { color: theme.colors.text }]}>{children}</Text>;
}

export function TextField({ multiline, style, ...props }: TextInputProps) {
  const theme = useTheme();
  return (
    <TextInput
      placeholderTextColor={theme.colors.secondaryText}
      multiline={multiline}
      {...props}
      style={[
        styles.input,
        { color: theme.colors.text, backgroundColor: theme.colors.surfaceStrong, borderColor: theme.colors.border },
        multiline && styles.multiline,
        style,
      ]}
    />
  );
}

/** A single-choice row of chips. Announced as radios so assistive tech reports the selection. */
export function ChoiceChips<T extends string>({
  values,
  value,
  labels,
  onChange,
}: {
  values: readonly T[];
  value: T;
  labels: Record<T, string>;
  onChange(value: T): void;
}) {
  const theme = useTheme();

  return (
    <View style={styles.chips}>
      {values.map((item) => {
        const selected = item === value;
        return (
          <Pressable
            key={item}
            accessibilityRole="radio"
            accessibilityState={{ checked: selected }}
            accessibilityLabel={labels[item]}
            onPress={() => onChange(item)}
            style={[styles.chip, {
              backgroundColor: selected ? theme.colors.accent : theme.colors.surfaceStrong,
              borderColor: theme.colors.border,
            }]}
          >
            <Text style={[styles.chipText, { color: selected ? theme.colors.onAccent : theme.colors.text }]}>
              {labels[item]}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function ToggleRow({ label, value, onChange }: { label: string; value: boolean; onChange(value: boolean): void }) {
  const theme = useTheme();
  return (
    <View style={styles.toggleRow}>
      <Text style={[styles.toggleLabel, { color: theme.colors.text }]}>{label}</Text>
      <Switch
        value={value}
        onValueChange={onChange}
        accessibilityLabel={label}
        trackColor={{ true: theme.colors.accent, false: theme.colors.border }}
      />
    </View>
  );
}

/** Marks output that is fixed demo data, so nothing in the preview reads as a real result. */
export function DemoBadge({ label = 'Interactive mockup' }: { label?: string }) {
  const theme = useTheme();
  return (
    <View style={[styles.badge, { backgroundColor: tint(theme.colors.warning) }]}>
      <Text style={[styles.badgeText, { color: theme.colors.warning }]}>{label.toLocaleUpperCase()}</Text>
    </View>
  );
}

export function Hint({ children }: { children: ReactNode }) {
  const theme = useTheme();
  return <Text style={[styles.hint, { color: theme.colors.secondaryText }]}>{children}</Text>;
}

const styles = StyleSheet.create({
  label: { fontSize: 14, fontWeight: '700' },
  input: {
    minHeight: minTapTarget + 2,
    borderWidth: 1,
    borderRadius: radius.sm,
    paddingHorizontal: space.md + 2,
    paddingVertical: 11,
    fontSize: 16,
  },
  multiline: { minHeight: 100, textAlignVertical: 'top' },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm },
  chip: {
    minHeight: 42,
    justifyContent: 'center',
    borderRadius: radius.pill,
    borderWidth: 1,
    paddingHorizontal: space.md + 2,
    paddingVertical: space.sm,
  },
  chipText: { fontSize: 14, fontWeight: '700' },
  toggleRow: { minHeight: 48, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: space.lg },
  toggleLabel: { flex: 1, fontWeight: '700' },
  badge: { alignSelf: 'flex-start', borderRadius: radius.pill, paddingHorizontal: 9, paddingVertical: 5 },
  badgeText: { fontSize: 9, fontWeight: '900', letterSpacing: 1 },
  hint: { fontSize: 13, lineHeight: 19 },
});
