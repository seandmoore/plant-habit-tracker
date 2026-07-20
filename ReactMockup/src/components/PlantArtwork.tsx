import { MaterialCommunityIcons } from '@expo/vector-icons';
import React from 'react';
import { Image, StyleSheet, View } from 'react-native';
import { usePlantTheme } from '@/theme/ThemeProvider';

interface PlantArtworkProps {
  photoUri?: string;
  size?: number;
  icon?: string;
}

export function PlantArtwork({ photoUri, size = 72, icon = 'leaf' }: PlantArtworkProps) {
  const theme = usePlantTheme();
  const radius = size * 0.28;
  if (photoUri) {
    return <Image source={{ uri: photoUri }} accessibilityIgnoresInvertColors style={{ width: size, height: size, borderRadius: radius }} />;
  }
  return (
    <View style={[styles.placeholder, { width: size, height: size, borderRadius: radius, backgroundColor: theme.colors.mint }]}>
      <MaterialCommunityIcons name={icon as never} size={size * 0.45} color={theme.colors.accentStrong} />
    </View>
  );
}

const styles = StyleSheet.create({ placeholder: { alignItems: 'center', justifyContent: 'center' } });
