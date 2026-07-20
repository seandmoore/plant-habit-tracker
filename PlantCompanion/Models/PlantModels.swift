import Foundation
import SwiftData

enum PlantEnvironment: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case indoor
    case outdoorContainer
    case outdoorGround

    var id: Self { self }

    var title: String {
        switch self {
        case .indoor: "Indoor"
        case .outdoorContainer: "Outdoor pot"
        case .outdoorGround: "Garden bed"
        }
    }
}

enum LightLevel: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case low
    case medium
    case brightIndirect
    case direct

    var id: Self { self }

    var title: String {
        switch self {
        case .low: "Low light"
        case .medium: "Medium light"
        case .brightIndirect: "Bright, indirect"
        case .direct: "Direct sun"
        }
    }
}

enum CareEventKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case watered
    case fertilized
    case pruned
    case repotted
    case healthNote

    var id: Self { self }

    var title: String {
        switch self {
        case .watered: "Watered"
        case .fertilized: "Fertilized"
        case .pruned: "Pruned"
        case .repotted: "Repotted"
        case .healthNote: "Health note"
        }
    }

    var symbol: String {
        switch self {
        case .watered: "drop.fill"
        case .fertilized: "sparkles"
        case .pruned: "scissors"
        case .repotted: "arrow.triangle.2.circlepath"
        case .healthNote: "cross.case.fill"
        }
    }
}

enum WaterUnit: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case milliliters = "mL"
    case fluidOunces = "fl oz"

    var id: Self { self }
}

struct PlantSpecies: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let commonName: String
    let scientificName: String
    let summary: String
    let baselineWateringDays: Int
    let light: String
    let soil: String
    let humidity: String
    let environments: [PlantEnvironment]
    let toxicityNote: String?
    let symbolName: String
}

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
        careEvents
            .filter { $0.kind == .watered }
            .map(\.timestamp)
            .max()
    }
}

@Model
final class CareEvent {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var timestamp: Date
    var amount: Double?
    var waterUnitRawValue: String?
    var note: String

    init(
        id: UUID = UUID(),
        kind: CareEventKind,
        timestamp: Date = .now,
        amount: Double? = nil,
        waterUnit: WaterUnit? = nil,
        note: String = ""
    ) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.timestamp = timestamp
        self.amount = amount
        self.waterUnitRawValue = waterUnit?.rawValue
        self.note = note
    }

    var kind: CareEventKind {
        get { CareEventKind(rawValue: kindRawValue) ?? .healthNote }
        set { kindRawValue = newValue.rawValue }
    }

    var waterUnit: WaterUnit? {
        get { waterUnitRawValue.flatMap(WaterUnit.init(rawValue:)) }
        set { waterUnitRawValue = newValue?.rawValue }
    }
}

struct CareRecommendation: Identifiable, Equatable {
    enum Status: Int, Comparable {
        case overdue
        case dueToday
        case upcoming

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let plantID: UUID
    let dueDate: Date
    let intervalDays: Int
    let status: Status
    let title: String
    let reason: String

    var id: UUID { plantID }
}

enum ScanMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case species
    case health
    case both

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

struct ScanCandidate: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let scientificName: String?
    let confidence: Double
    let detail: String
    let source: String
}

struct CompanionPrompt: Sendable {
    let question: String
    let plantName: String?
    let groundedFacts: [String]
}

struct CompanionMessage: Identifiable, Equatable, Sendable {
    enum Role: Hashable, Sendable { case companion, user }
    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

struct WateringReminderRequest: Sendable {
    let plantID: UUID
    let plantName: String
    let dueDate: Date
    let hour: Int
}
