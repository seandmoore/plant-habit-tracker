import { Alert, Platform } from 'react-native';

/** Bridges to the platform confirmation: a native alert, or the browser dialog on web. */
export function confirmAction(
  title: string,
  message: string,
  actionLabel: string,
  action: () => void,
  destructive = false,
): void {
  if (Platform.OS === 'web') {
    const confirm = (globalThis as typeof globalThis & { confirm?: (value: string) => boolean }).confirm;
    if (!confirm || confirm(`${title}\n\n${message}`)) action();
    return;
  }

  Alert.alert(title, message, [
    { text: 'Cancel', style: 'cancel' },
    { text: actionLabel, style: destructive ? 'destructive' : 'default', onPress: action },
  ]);
}
