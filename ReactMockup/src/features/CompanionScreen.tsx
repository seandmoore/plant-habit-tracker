import { useLocalSearchParams } from 'expo-router';
import React, { useMemo, useRef, useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { environmentLabels, lightLabels } from '@/domain/labels';
import { createId } from '@/domain/id';
import { groundingFacts } from '@/domain/selectors';
import type { CompanionMessage } from '@/domain/types';
import { services, welcomeMessage } from '@/services';
import { usePlant } from '@/state/selectors';
import {
  Button,
  CompanionRing,
  DemoBadge,
  ModalScreen,
  space,
  TextField,
  useTheme,
} from '@/ui';
import type { CompanionVisualState } from '@/ui';

export function CompanionScreen() {
  const { plantId } = useLocalSearchParams<{ plantId?: string }>();
  const plant = usePlant(plantId);
  const theme = useTheme();

  const [messages, setMessages] = useState<CompanionMessage[]>([welcomeMessage]);
  const [question, setQuestion] = useState('');
  const [visualState, setVisualState] = useState<CompanionVisualState>('idle');
  const scrollRef = useRef<ScrollView>(null);

  // The companion only ever sees saved records — never invented plant facts.
  const facts = useMemo(
    () => (plant ? groundingFacts(plant, environmentLabels[plant.environment], lightLabels[plant.light]) : []),
    [plant],
  );

  const send = async () => {
    const trimmed = question.trim();
    if (!trimmed || visualState === 'thinking') return;

    setQuestion('');
    setMessages((current) => [...current, { id: createId('message'), role: 'user', text: trimmed }]);
    setVisualState('thinking');

    try {
      const answer = await services.companion.respond(trimmed, facts);
      setMessages((current) => [...current, { id: createId('message'), role: 'companion', text: answer }]);
      setVisualState('speaking');
    } catch {
      setMessages((current) => [...current, {
        id: createId('message'),
        role: 'companion',
        text: 'I couldn’t prepare that answer just now. Your plant records are still safe, and you can try again.',
      }]);
      setVisualState('idle');
      return;
    }

    setTimeout(() => setVisualState('idle'), 650);
  };

  return (
    <ModalScreen title={plant ? `Ask about ${plant.nickname}` : 'Plant Companion'} scroll={false}>
      <View style={styles.root}>
        <View style={styles.header}>
          <CompanionRing state={visualState} />
          <DemoBadge label="Scripted demo companion" />
          <Text style={[styles.grounding, { color: theme.colors.secondaryText }]}>
            {plant
              ? `Answers use ${plant.nickname}’s saved mock details.`
              : 'Choose a plant first for grounded, contextual replies.'}
          </Text>
        </View>

        <ScrollView
          ref={scrollRef}
          style={styles.messages}
          contentContainerStyle={styles.messageContent}
          onContentSizeChange={() => scrollRef.current?.scrollToEnd({ animated: true })}
        >
          {messages.map((message) => {
            const fromUser = message.role === 'user';
            return (
              <View
                key={message.id}
                accessibilityLabel={`${fromUser ? 'You' : 'Companion'}: ${message.text}`}
                style={[
                  styles.bubble,
                  fromUser ? styles.userBubble : styles.companionBubble,
                  { backgroundColor: fromUser ? theme.colors.accent : theme.colors.mint },
                ]}
              >
                <Text style={{ color: fromUser ? theme.colors.onAccent : theme.colors.text, lineHeight: 21 }}>
                  {message.text}
                </Text>
              </View>
            );
          })}

          {visualState === 'thinking' ? (
            <Text style={{ color: theme.colors.secondaryText }}>Thinking with your plant records…</Text>
          ) : null}
        </ScrollView>

        <View style={styles.composer}>
          <TextField
            value={question}
            onChangeText={setQuestion}
            placeholder="Ask about care"
            accessibilityLabel="Ask about care"
            multiline
            style={styles.input}
            onSubmitEditing={() => void send()}
          />
          <Button
            label="Send"
            icon="arrow-up"
            onPress={() => void send()}
            disabled={!question.trim()}
            loading={visualState === 'thinking'}
          />
        </View>
      </View>
    </ModalScreen>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, minHeight: 420, gap: space.md, padding: space.xl - 4 },
  header: { alignItems: 'center', gap: 9 },
  grounding: { textAlign: 'center', fontSize: 12 },
  messages: { flex: 1 },
  messageContent: { gap: space.sm + 2, paddingVertical: space.sm },
  bubble: { maxWidth: '84%', paddingHorizontal: space.md + 2, paddingVertical: 11, borderRadius: 18 },
  userBubble: { alignSelf: 'flex-end' },
  companionBubble: { alignSelf: 'flex-start' },
  composer: { flexDirection: 'row', alignItems: 'flex-end', gap: 9 },
  input: { flex: 1, maxHeight: 110, minHeight: 48 },
});
