import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { CareRecommendation } from '@/domain/types';
import { usePlantTheme } from '@/theme/ThemeProvider';

export function StatusPill({ recommendation }: { recommendation: CareRecommendation }) {
  const theme = usePlantTheme();
  const color = recommendation.status === 'overdue'
    ? theme.colors.warning
    : recommendation.status === 'dueToday' ? theme.colors.accent : theme.colors.secondaryText;
  return (
    <View style={[styles.pill, { backgroundColor: `${color}1F` }]}>
      <MaterialCommunityIcons name={recommendation.status === 'upcoming' ? 'calendar-blank' : 'water'} size={14} color={color} />
      <Text style={[styles.text, { color }]}>{recommendation.title}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: { alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center', gap: 6, borderRadius: 999, paddingHorizontal: 10, paddingVertical: 6 },
  text: { fontSize: 12, lineHeight: 15, fontWeight: '700' },
});
