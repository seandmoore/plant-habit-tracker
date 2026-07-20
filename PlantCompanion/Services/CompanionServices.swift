import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

actor ScriptedCompanionService: CompanionService {
    func respond(to prompt: CompanionPrompt) async throws -> String {
        try await Task.sleep(for: .milliseconds(300))
        let question = prompt.question.lowercased()
        let name = prompt.plantName ?? "your plant"
        let facts = prompt.groundedFacts.prefix(2).joined(separator: " ")

        if question.contains("water") || question.contains("dry") {
            return "For \(name), use the care check date as a reminder—not a command. Feel the soil first, then water thoroughly if the root zone is appropriately dry. \(facts)"
        }
        if question.contains("yellow") || question.contains("brown") || question.contains("sick") {
            return "Leaf changes can have several causes. Check soil moisture, drainage, light, temperature, and pests, then compare the newest growth over several days. A photo suggestion is not a diagnosis. \(facts)"
        }
        if question.contains("light") || question.contains("sun") {
            return "Observe how light moves through the space across the day. Change placement gradually and watch new growth for the clearest signal. \(facts)"
        }
        if prompt.groundedFacts.isEmpty {
            return "I can help you add a plant, understand today’s care checks, log watering, or prepare a clear photo for identification. What would you like to do?"
        }
        return "Here’s what the app knows about \(name): \(facts) I can explain a care check or help you log what you observe."
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
actor FoundationModelCompanionService: CompanionService {
    private let fallback = ScriptedCompanionService()

    func respond(to prompt: CompanionPrompt) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return try await fallback.respond(to: prompt)
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are a warm, concise plant-care companion. Only use facts supplied in the prompt.
            Never invent plant facts or diagnose disease. Treat dates as reminders to inspect the plant,
            not commands to water. Say when the available facts are insufficient.
            """
        )
        let grounding = prompt.groundedFacts.isEmpty
            ? "No verified plant facts are available."
            : prompt.groundedFacts.map { "- \($0)" }.joined(separator: "\n")
        let response = try await session.respond(
            to: "Plant: \(prompt.plantName ?? "not selected")\nVerified facts:\n\(grounding)\nQuestion: \(prompt.question)"
        )
        return response.content
    }
}
#endif

struct CompanionServiceFactory {
    static func makeDefault() -> any CompanionService {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return FoundationModelCompanionService()
        }
        #endif
        return ScriptedCompanionService()
    }
}
