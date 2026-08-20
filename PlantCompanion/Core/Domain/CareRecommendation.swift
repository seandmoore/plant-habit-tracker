import Foundation

/// Everything the planner needs, and nothing about how a plant is stored. Keeping this
/// separate from `UserPlant` lets the contract's golden vectors exercise the planner without
/// a SwiftData container, and keeps the rules usable off the main actor.
struct CareProfile: Hashable, Sendable {
    let baselineWateringDays: Int
    let environment: PlantEnvironment
    let light: LightLevel
    /// The most recent watering, or the day the plant was added.
    let anchor: Date
}

struct CareRecommendation: Identifiable, Hashable, Sendable {
    enum Status: Int, Comparable, Sendable {
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

    var needsAttention: Bool { status != .upcoming }
}
