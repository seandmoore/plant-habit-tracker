import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    enum Destination: String, CaseIterable, Identifiable, Hashable {
        case today
        case plants
        case scan
        case discover

        var id: Self { self }

        var title: String {
            switch self {
            case .today: "Today"
            case .plants: "My Plants"
            case .scan: "Scan"
            case .discover: "Discover"
            }
        }

        var symbol: String {
            switch self {
            case .today: "sun.max.fill"
            case .plants: "leaf.fill"
            case .scan: "viewfinder"
            case .discover: "magnifyingglass"
            }
        }
    }

    enum CompanionState: Hashable {
        case idle
        case thinking
        case speaking
    }

    var selectedDestination: Destination = .today
    var catalog: [PlantSpecies] = []
    var catalogError: String?
    var isCompanionPresented = false
    var companionState: CompanionState = .idle
    var companionPlant: UserPlant?
    var companionMessages: [CompanionMessage] = [
        CompanionMessage(role: .companion, text: "Hi, I’m here to make plant care feel calm and understandable. Ask me about today’s care checks or one of your plants.")
    ]

    @ObservationIgnored let catalogService: any PlantCatalogService
    @ObservationIgnored let identificationService: any IdentificationService
    @ObservationIgnored let recommendationEngine: any RecommendationEngine
    @ObservationIgnored let companionService: any CompanionService
    @ObservationIgnored let notifications: any NotificationScheduling

    init(
        catalogService: (any PlantCatalogService)? = nil,
        identificationService: (any IdentificationService)? = nil,
        recommendationEngine: any RecommendationEngine = DefaultRecommendationEngine(),
        companionService: (any CompanionService)? = nil,
        notifications: any NotificationScheduling = LocalNotificationScheduler()
    ) {
        self.catalogService = catalogService ?? Self.makeCatalogService()
        self.identificationService = identificationService ?? Self.makeIdentificationService()
        self.recommendationEngine = recommendationEngine
        self.companionService = companionService ?? CompanionServiceFactory.makeDefault()
        self.notifications = notifications
    }

    func loadCatalog(query: String = "") async {
        do {
            catalog = try await catalogService.search(query: query)
            catalogError = nil
        } catch {
            catalogError = error.localizedDescription
        }
    }

    func presentCompanion(for plant: UserPlant? = nil) {
        companionPlant = plant
        isCompanionPresented = true
    }

    func askCompanion(_ question: String) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        companionMessages.append(CompanionMessage(role: .user, text: trimmed))
        companionState = .thinking
        let prompt = CompanionPrompt(
            question: trimmed,
            plantName: companionPlant?.nickname,
            groundedFacts: companionFacts()
        )

        do {
            let response = try await companionService.respond(to: prompt)
            companionMessages.append(CompanionMessage(role: .companion, text: response))
        } catch {
            companionMessages.append(CompanionMessage(role: .companion, text: "I couldn’t prepare that answer just now. Your plant records are still safe, and you can try again."))
        }
        companionState = .speaking
        try? await Task.sleep(for: .milliseconds(650))
        companionState = .idle
    }

    func scheduleReminder(for plant: UserPlant) async throws {
        guard plant.reminderEnabled else {
            await notifications.cancelWateringReminder(for: plant.id)
            return
        }
        let granted = try await notifications.requestAuthorization()
        guard granted else { return }
        let recommendation = recommendationEngine.wateringRecommendation(for: plant, asOf: .now)
        try await notifications.scheduleWateringReminder(
            WateringReminderRequest(
                plantID: plant.id,
                plantName: plant.nickname,
                dueDate: recommendation.dueDate,
                hour: plant.reminderHour
            )
        )
    }

    private func companionFacts() -> [String] {
        guard let plant = companionPlant else { return [] }
        let recommendation = recommendationEngine.wateringRecommendation(for: plant, asOf: .now)
        return [
            "\(plant.nickname) is recorded as \(plant.commonName) (\(plant.scientificName)).",
            "It is \(plant.environment.title.lowercased()) in \(plant.light.title.lowercased()).",
            "The next recommendation says: \(recommendation.title). \(recommendation.reason)",
            plant.lastWateredAt.map { "The latest watering log is dated \($0.formatted(date: .abbreviated, time: .omitted))." }
        ].compactMap { $0 }
    }

    private static func makeIdentificationService() -> any IdentificationService {
        if let rawURL = Bundle.main.object(forInfoDictionaryKey: "PLANTNET_PROXY_URL") as? String,
           !rawURL.isEmpty,
           let url = URL(string: rawURL) {
            return ProxyIdentificationService(baseURL: url)
        }
        return MockIdentificationService()
    }

    private static func makeCatalogService() -> any PlantCatalogService {
        let starter = StarterCatalogService()
        if let rawURL = Bundle.main.object(forInfoDictionaryKey: "PLANTNET_PROXY_URL") as? String,
           !rawURL.isEmpty,
           let url = URL(string: rawURL) {
            return ResilientCatalogService(primary: ProxyPlantCatalogService(baseURL: url), fallback: starter)
        }
        return starter
    }
}
