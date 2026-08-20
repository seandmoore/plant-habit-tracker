import Foundation

/// Where a plant lives. Drives the first interval modifier in `CareRules`.
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

    var symbolName: String {
        switch self {
        case .indoor: "house.fill"
        case .outdoorContainer, .outdoorGround: "sun.max.fill"
        }
    }
}

/// How much light a plant receives where it stands. Drives the second interval modifier.
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

    var symbolName: String {
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

    /// Matches the unit people in this locale are most likely to reach for.
    static var localeDefault: WaterUnit {
        Locale.current.measurementSystem == .us ? .fluidOunces : .milliliters
    }
}
