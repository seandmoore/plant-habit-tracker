import type { CompanionMessage } from '@/domain/types';
import type { CompanionService } from './types';

const delay = (milliseconds: number) => new Promise((resolve) => setTimeout(resolve, milliseconds));

/**
 * A scripted stand-in for the native app's on-device model. Each branch answers from the
 * facts it was handed and refuses to act as a botanical database — the same guardrail the
 * real companion prompt enforces.
 */
export const scriptedCompanionService: CompanionService = {
  async respond(question, facts) {
    await delay(350);
    const normalized = question.toLocaleLowerCase();
    const grounding = facts.slice(0, 2).join(' ');

    if (normalized.includes('water') || normalized.includes('dry')) {
      return `Use the care date as a reminder, not a command. Feel the soil first, then water if the root zone is appropriately dry. ${grounding}`.trim();
    }
    if (normalized.includes('yellow') || normalized.includes('brown') || normalized.includes('sick')) {
      return `Leaf changes can have several causes. Check moisture, drainage, light, temperature, and pests. A photo suggestion is not a diagnosis. ${grounding}`.trim();
    }
    if (normalized.includes('light') || normalized.includes('sun')) {
      return `Observe how light moves through the space and change placement gradually. ${grounding}`.trim();
    }
    return grounding || 'I can help you add a plant, understand care checks, log watering, or prepare a clear photo for identification.';
  },
};

export const welcomeMessage: CompanionMessage = {
  id: 'companion-welcome',
  role: 'companion',
  text: 'Hi, I’m here to make plant care feel calm and understandable. Ask me about today’s care checks or one of your plants.',
};
