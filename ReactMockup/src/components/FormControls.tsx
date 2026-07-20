import React, { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';
import { usePlantTheme } from '@/theme/ThemeProvider';

export function FieldLabel({ children }: { children: ReactNode }) {
  const theme = usePlantTheme();
  return <Text style={[styles.label, { color: theme.colors.text }]}>{children}</Text>;
}

export function AppTextInput(props: TextInputProps) {
  const theme = usePlantTheme();
  return (
    <TextInput
      placeholderTextColor={theme.colors.secondaryText}
      {...props}
      style={[styles.input, { color: theme.colors.text, backgroundColor: theme.colors.surfaceStrong, borderColor: theme.colors.border }, props.style]}
    />
  );
}

export function ChoiceChips<T extends string>({ values, value, labels, onChange }: { values: readonly T[]; value: T; labels: Record<T, string>; onChange(value: T): void }) {
  const theme = usePlantTheme();
  return (
    <View style={styles.chips}>
      {values.map((item) => {
        const selected = item === value;
        return (
          <Pressable key={item} accessibilityRole="radio" accessibilityState={{ checked: selected }} onPress={() => onChange(item)} style={[styles.chip, { backgroundColor: selected ? theme.colors.accent : theme.colors.surfaceStrong, borderColor: theme.colors.border }]}>
            <Text style={[styles.chipText, { color: selected ? '#FFFFFF' : theme.colors.text }]}>{labels[item]}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function DemoBadge({ label = 'Interactive mockup' }: { label?: string }) {
  const theme = usePlantTheme();
  return (
    <View style={[styles.badge, { backgroundColor: `${theme.colors.warning}1F` }]}>
      <Text style={[styles.badgeText, { color: theme.colors.warning }]}>{label.toLocaleUpperCase()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  label: { fontSize: 14, fontWeight: '700', marginBottom: 6 },
  input: { minHeight: 48, borderWidth: 1, borderRadius: 14, paddingHorizontal: 14, paddingVertical: 11, fontSize: 16 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { minHeight: 42, justifyContent: 'center', borderRadius: 999, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 8 },
  chipText: { fontSize: 14, fontWeight: '700' },
  badge: { alignSelf: 'flex-start', borderRadius: 999, paddingHorizontal: 9, paddingVertical: 5 },
  badgeText: { fontSize: 9, fontWeight: '900', letterSpacing: 1 },
});
