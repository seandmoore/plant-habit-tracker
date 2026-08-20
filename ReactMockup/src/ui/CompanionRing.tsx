import { MaterialCommunityIcons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import React, { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, Easing, Platform, Pressable, StyleSheet, View } from 'react-native';
import { useTheme } from './ThemeProvider';

export type CompanionVisualState = 'idle' | 'thinking' | 'speaking';

const iconFor = (state: CompanionVisualState): string =>
  state === 'thinking' ? 'dots-horizontal' : state === 'speaking' ? 'auto-fix' : 'leaf';

/** Spins only while the companion is thinking, and never when Reduce Motion is on. */
export function CompanionRing({
  state = 'idle',
  onPress,
  size = 60,
}: {
  state?: CompanionVisualState;
  onPress?(): void;
  size?: number;
}) {
  const theme = useTheme();
  const rotation = useRef(new Animated.Value(0)).current;
  const [reduceMotion, setReduceMotion] = useState(false);

  useEffect(() => {
    void AccessibilityInfo.isReduceMotionEnabled().then(setReduceMotion);
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
    return () => subscription.remove();
  }, []);

  useEffect(() => {
    if (state !== 'thinking' || reduceMotion) {
      rotation.stopAnimation();
      rotation.setValue(0);
      return;
    }
    const animation = Animated.loop(
      Animated.timing(rotation, { toValue: 1, duration: 1250, easing: Easing.linear, useNativeDriver: true }),
    );
    animation.start();
    return () => animation.stop();
  }, [reduceMotion, rotation, state]);

  const rotate = rotation.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '360deg'] });

  const ring = (
    <View style={[styles.shell, { width: size, height: size, borderRadius: size / 2, shadowColor: theme.colors.shadow }]}>
      {Platform.OS !== 'web' && <BlurView intensity={45} tint={theme.dark ? 'dark' : 'light'} style={StyleSheet.absoluteFill} />}
      <Animated.View style={[styles.ring, { borderColor: theme.colors.accent, borderRadius: size / 2, transform: [{ rotate }] }]} />
      <View style={[styles.center, { backgroundColor: theme.colors.mint }]}>
        <MaterialCommunityIcons name={iconFor(state) as never} size={size * 0.36} color={theme.colors.accentStrong} />
      </View>
    </View>
  );

  // Decorative uses (onboarding, the chat header) pass no handler and stay out of the tab order.
  if (!onPress) return <View accessibilityElementsHidden importantForAccessibility="no-hide-descendants">{ring}</View>;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel="Plant companion"
      accessibilityHint="Opens care help and plant questions"
      onPress={onPress}
    >
      {ring}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  shell: {
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    shadowOpacity: 1,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 5 },
    elevation: 6,
  },
  ring: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    borderWidth: 4,
    borderTopColor: '#67BDA0',
    borderRightColor: '#BDE0C3',
  },
  center: { width: '72%', height: '72%', borderRadius: 999, alignItems: 'center', justifyContent: 'center' },
});
