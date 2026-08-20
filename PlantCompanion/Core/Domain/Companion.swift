import Foundation

/// A question plus the saved records the companion is allowed to use. Assembling the facts
/// outside the model is what keeps the guardrail checkable: the language model never acts as a
/// botanical database or a care calculator.
struct CompanionPrompt: Hashable, Sendable {
    let question: String
    let plantName: String?
    let groundedFacts: [String]
}

struct CompanionMessage: Identifiable, Hashable, Sendable {
    enum Role: Hashable, Sendable {
        case companion
        case user
    }

    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }

    static let welcome = CompanionMessage(
        role: .companion,
        text: "Hi, I’m here to make plant care feel calm and understandable. Ask me about today’s care checks or one of your plants."
    )

    static let failure = CompanionMessage(
        role: .companion,
        text: "I couldn’t prepare that answer just now. Your plant records are still safe, and you can try again."
    )
}

/// A reminder to inspect a plant. Never a command to water it.
struct WateringReminderRequest: Hashable, Sendable {
    let plantID: UUID
    let plantName: String
    let dueDate: Date
    let hour: Int
}
