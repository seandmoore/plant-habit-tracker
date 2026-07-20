import { Alert, Platform } from 'react-native';

export const confirmAction = (title: string, message: string, actionLabel: string, action: () => void, destructive = false) => {
  if (Platform.OS === 'web') {
    const confirm = (globalThis as typeof globalThis & { confirm?: (value: string) => boolean }).confirm;
    if (!confirm || confirm(`${title}\n\n${message}`)) action();
    return;
  }
  Alert.alert(title, message, [
    { text: 'Cancel', style: 'cancel' },
    { text: actionLabel, style: destructive ? 'destructive' : 'default', onPress: action },
  ]);
};
