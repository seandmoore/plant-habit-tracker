import Foundation
import Observation

/// The companion transcript. This used to live on the app-wide model, which meant an unrelated
/// screen re-rendered whenever a message arrived; it belongs to the conversation instead.
@MainActor
@Observable
final class CompanionConversation {
    private(set) var messages: [CompanionMessage] = [.welcome]
    private(set) var state: CompanionState = .idle

    var isBusy: Bool { state == .thinking }

    /// Facts come from saved records only. The model is never used as a botanical database or a
    /// care calculator, so anything it says can be traced to something the app already knew.
    static func facts(for plant: UserPlant, recommendation: CareRecommendation) -> [String] {
        var facts = [
            "\(plant.nickname) is recorded as \(plant.commonName) (\(plant.scientificName)).",
            "It is \(plant.environment.title.lowercased()) in \(plant.light.title.lowercased()).",
            "The next recommendation says: \(recommendation.title) \(recommendation.reason)"
        ]
        if let lastWatered = plant.lastWateredAt {
            facts.append("The latest watering log is dated \(lastWatered.formatted(date: .abbreviated, time: .omitted)).")
        }
        return facts
    }

    func ask(
        _ question: String,
        plantName: String?,
        facts: [String],
        using service: any CompanionService
    ) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isBusy else { return }

        messages.append(CompanionMessage(role: .user, text: trimmed))
        state = .thinking

        let prompt = CompanionPrompt(question: trimmed, plantName: plantName, groundedFacts: facts)
        do {
            let answer = try await service.respond(to: prompt)
            messages.append(CompanionMessage(role: .companion, text: answer))
            state = .speaking
        } catch {
            messages.append(.failure)
            state = .idle
            return
        }

        try? await Task.sleep(for: .milliseconds(650))
        state = .idle
    }
}
