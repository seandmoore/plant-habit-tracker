import Foundation
import SwiftData

@Model
final class UserPlant {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var speciesID: String
    var commonName: String
    var scientificName: String
    var environmentRawValue: String
    var lightRawValue: String
    var locationName: String
    var dateAdded: Date
    var baselineWateringDays: Int
    var reminderEnabled: Bool
    var reminderHour: Int
    var notes: String
    @Attribute(.externalStorage) var photoData: Data?
    @Relationship(deleteRule: .cascade) var careEvents: [CareEvent]

    init(
        id: UUID = UUID(),
        nickname: String,
        species: PlantSpecies,
        environment: PlantEnvironment,
        light: LightLevel,
        locationName: String = "",
        dateAdded: Date = .now,
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        notes: String = "",
        photoData: Data? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.speciesID = species.id
        self.commonName = species.commonName
        self.scientificName = species.scientificName
        self.environmentRawValue = environment.rawValue
        self.lightRawValue = light.rawValue
        self.locationName = locationName
        self.dateAdded = dateAdded
        self.baselineWateringDays = species.baselineWateringDays
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.notes = notes
        self.photoData = photoData
        self.careEvents = []
    }

    // Enums are stored as raw values so SwiftData migrations stay simple; these keep call
    // sites working in typed terms.
    var environment: PlantEnvironment {
        get { PlantEnvironment(rawValue: environmentRawValue) ?? .indoor }
        set { environmentRawValue = newValue.rawValue }
    }

    var light: LightLevel {
        get { LightLevel(rawValue: lightRawValue) ?? .brightIndirect }
        set { lightRawValue = newValue.rawValue }
    }

    var sortedCareEvents: [CareEvent] {
        careEvents.sorted { $0.timestamp > $1.timestamp }
    }

    var lastWateredAt: Date? {
        careEvents.lazy.filter { $0.kind == .watered }.map(\.timestamp).max()
    }

    /// A `Sendable` snapshot of everything the planner needs, so a stored model never has to
    /// cross an actor boundary to be scheduled or explained.
    var careProfile: CareProfile {
        CareProfile(
            baselineWateringDays: baselineWateringDays,
            environment: environment,
            light: light,
            anchor: lastWateredAt ?? dateAdded
        )
    }

    func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return nickname.localizedCaseInsensitiveContains(trimmed)
            || commonName.localizedCaseInsensitiveContains(trimmed)
            || scientificName.localizedCaseInsensitiveContains(trimmed)
    }
}
