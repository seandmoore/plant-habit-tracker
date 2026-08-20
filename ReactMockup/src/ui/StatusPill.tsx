import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import type { CareRecommendation } from '@/domain/types';
import { radius, space, tint } from './theme';
import { useTheme } from './ThemeProvider';

export function StatusPill({ recommendation }: { recommendation: CareRecommendation }) {
  const theme = useTheme();
  const color = recommendation.status === 'overdue'
    ? theme.colors.warning
    : recommendation.status === 'dueToday' ? theme.colors.accent : theme.colors.secondaryText;

  return (
    <View style={[styles.pill, { backgroundColor: tint(color) }]}>
      <MaterialCommunityIcons
        name={recommendation.status === 'upcoming' ? 'calendar-blank' : 'water'}
        size={14}
        color={color}
      />
      <Text style={[styles.text, { color }]}>{recommendation.title}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.xs + 2,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: space.sm - 2,
  },
  text: { fontSize: 12, fontWeight: '800' },
});
