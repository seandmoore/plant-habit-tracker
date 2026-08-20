import Foundation

/// The watering rules as data, mirroring `Contract/care-rules.json`.
/// `ContractParityTests` fails if the two diverge, so a rule change has to land here and in the
/// other implementations together.
///
/// Expressing the rules as tables rather than a chain of `if` statements is what lets
/// `WateringPlanner` build the interval and its human explanation in a single pass: the phrase
/// travels with the number that moved it, so the app can always say *why* a date is what it is.
enum CareRules {
    static let version = 1

    static let minimumIntervalDays = 1
    static let maximumIntervalDays = 45

    struct Modifier<Key: Hashable & Sendable>: Sendable {
        let key: Key
        let days: Int
        let factor: String?
    }

    struct SeasonModifier: Sendable {
        let key: String
        let months: [Int]
        let days: Int
        let factor: String?
        let excludedEnvironments: [PlantEnvironment]
    }

    static let environmentModifiers: [Modifier<PlantEnvironment>] = [
        Modifier(key: .indoor, days: 0, factor: "kept indoors"),
        Modifier(key: .outdoorContainer, days: -2, factor: "an outdoor pot can dry faster"),
        Modifier(key: .outdoorGround, days: 1, factor: "garden soil holds moisture longer than many pots")
    ]

    static let lightModifiers: [Modifier<LightLevel>] = [
        Modifier(key: .low, days: 2, factor: "lower light usually slows water use"),
        Modifier(key: .medium, days: 0, factor: nil),
        Modifier(key: .brightIndirect, days: -1, factor: "bright light can increase water use"),
        Modifier(key: .direct, days: -2, factor: "direct sun can dry soil faster")
    ]

    /// Ordered by precedence: at most one season modifier applies, and the warm window wins.
    static let seasonModifiers: [SeasonModifier] = [
        SeasonModifier(
            key: "warmOutdoor",
            months: [6, 7, 8],
            days: -2,
            factor: "it is the warmer part of the year",
            excludedEnvironments: [.indoor]
        ),
        SeasonModifier(
            key: "cool",
            months: [11, 12, 1, 2],
            days: 2,
            factor: "plants often use less water in cooler months",
            excludedEnvironments: []
        )
    ]

    /// Held here so all three apps word an explanation identically.
    enum Phrasing {
        static let overdueTitle = "Check soil now"
        static let dueTodayTitle = "Check soil today"
        static let explanationWithoutFactors = "Based on this species’ starting care interval."
        static let reasonSuffix = "Feel the soil before watering."

        static func upcomingTitle(days: Int) -> String {
            "Check soil in \(days) day\(days == 1 ? "" : "s")"
        }

        static func explanation(factors: [String]) -> String {
            guard !factors.isEmpty else { return explanationWithoutFactors }
            return "Based on its starting interval and the fact that it is \(factors.joined(separator: ", "))."
        }
    }

    static func environmentModifier(for environment: PlantEnvironment) -> Modifier<PlantEnvironment>? {
        environmentModifiers.first { $0.key == environment }
    }

    static func lightModifier(for light: LightLevel) -> Modifier<LightLevel>? {
        lightModifiers.first { $0.key == light }
    }

    static func seasonModifier(month: Int, environment: PlantEnvironment) -> SeasonModifier? {
        seasonModifiers.first { $0.months.contains(month) && !$0.excludedEnvironments.contains(environment) }
    }
}
