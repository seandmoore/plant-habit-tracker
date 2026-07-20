import { useLocalSearchParams } from 'expo-router';
import React, { useMemo, useRef, useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { AppButton } from '@/components/Buttons';
import { CompanionRing, CompanionVisualState } from '@/components/CompanionRing';
import { AppTextInput, DemoBadge } from '@/components/FormControls';
import { ModalScaffold } from '@/components/ModalScaffold';
import { createId } from '@/domain/id';
import { lightLabels, environmentLabels } from '@/domain/labels';
import { wateringRecommendation } from '@/domain/recommendations';
import { CompanionMessage } from '@/domain/types';
import { initialCompanionMessages, mockCompanionService } from '@/services/mockServices';
import { usePlantStore } from '@/store/PlantStore';
import { usePlantTheme } from '@/theme/ThemeProvider';

export default function CompanionScreen() {
  const { plantId } = useLocalSearchParams<{ plantId?: string }>();
  const { state } = usePlantStore();
  const plant = state.plants.find((item) => item.id === plantId);
  const [messages, setMessages] = useState<CompanionMessage[]>(initialCompanionMessages);
  const [question, setQuestion] = useState('');
  const [visualState, setVisualState] = useState<CompanionVisualState>('idle');
  const scrollRef = useRef<ScrollView>(null);
  const theme = usePlantTheme();
  const facts = useMemo(() => {
    if (!plant) return [];
    const recommendation = wateringRecommendation(plant);
    return [
      `${plant.nickname} is recorded as ${plant.commonName} (${plant.scientificName}).`,
      `It is ${environmentLabels[plant.environment].toLocaleLowerCase()} in ${lightLabels[plant.light].toLocaleLowerCase()}.`,
      `${recommendation.title}. ${recommendation.reason}`,
    ];
  }, [plant]);

  const send = async () => {
    const trimmed = question.trim();
    if (!trimmed || visualState === 'thinking') return;
    setQuestion('');
    setMessages((current) => [...current, { id: createId('message'), role: 'user', text: trimmed }]);
    setVisualState('thinking');
    const response = await mockCompanionService.respond(trimmed, facts);
    setMessages((current) => [...current, { id: createId('message'), role: 'companion', text: response }]);
    setVisualState('speaking');
    setTimeout(() => setVisualState('idle'), 650);
  };

  return (
    <ModalScaffold title={plant ? `Ask about ${plant.nickname}` : 'Plant Companion'} scroll={false}>
      <View style={styles.root}>
        <View style={styles.header}>
          <CompanionRing state={visualState} onPress={() => undefined} />
          <DemoBadge label="Scripted demo companion" />
          <Text style={[styles.grounding, { color: theme.colors.secondaryText }]}>{plant ? `Answers use ${plant.nickname}’s saved mock details.` : 'Choose a plant first for grounded, contextual replies.'}</Text>
        </View>
        <ScrollView ref={scrollRef} style={styles.messages} contentContainerStyle={styles.messageContent} onContentSizeChange={() => scrollRef.current?.scrollToEnd({ animated: true })}>
          {messages.map((message) => (
            <View key={message.id} accessibilityLabel={`${message.role === 'user' ? 'You' : 'Companion'}: ${message.text}`} style={[styles.bubble, message.role === 'user' ? styles.userBubble : styles.companionBubble, { backgroundColor: message.role === 'user' ? theme.colors.accent : theme.colors.mint }]}>
              <Text style={{ color: message.role === 'user' ? '#FFFFFF' : theme.colors.text, lineHeight: 21 }}>{message.text}</Text>
            </View>
          ))}
          {visualState === 'thinking' ? <Text style={{ color: theme.colors.secondaryText }}>Thinking with your plant records…</Text> : null}
        </ScrollView>
        <View style={styles.composer}>
          <AppTextInput value={question} onChangeText={setQuestion} placeholder="Ask about care" multiline style={styles.input} onSubmitEditing={() => void send()} />
          <AppButton label="Send" icon="arrow-up" onPress={() => void send()} disabled={!question.trim()} loading={visualState === 'thinking'} />
        </View>
      </View>
    </ModalScaffold>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, minHeight: 420, gap: 12 },
  header: { alignItems: 'center', gap: 9 },
  grounding: { textAlign: 'center', fontSize: 12 },
  messages: { flex: 1 },
  messageContent: { gap: 10, paddingVertical: 8 },
  bubble: { maxWidth: '84%', paddingHorizontal: 14, paddingVertical: 11, borderRadius: 18 },
  userBubble: { alignSelf: 'flex-end' },
  companionBubble: { alignSelf: 'flex-start' },
  composer: { flexDirection: 'row', alignItems: 'flex-end', gap: 9 },
  input: { flex: 1, maxHeight: 110 },
});
