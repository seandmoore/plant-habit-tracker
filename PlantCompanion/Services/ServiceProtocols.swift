import Foundation

protocol PlantCatalogService: Sendable {
    func search(query: String) async throws -> [PlantSpecies]
    func species(id: String) async throws -> PlantSpecies?
}

protocol IdentificationService: Sendable {
    func identify(imageData: Data, mode: ScanMode) async throws -> [ScanCandidate]
}

protocol CompanionService: Sendable {
    func respond(to prompt: CompanionPrompt) async throws -> String
}

protocol RecommendationEngine: Sendable {
    func wateringRecommendation(for plant: UserPlant, asOf date: Date) -> CareRecommendation
}

protocol NotificationScheduling: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleWateringReminder(_ request: WateringReminderRequest) async throws
    func cancelWateringReminder(for plantID: UUID) async
}

enum PlantServiceError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case requestFailed(String)
    case featureUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "This service has not been configured yet."
        case .invalidResponse: "The plant service returned an unreadable response."
        case .requestFailed(let message): message
        case .featureUnavailable: "This feature is not available on this device."
        }
    }
}
