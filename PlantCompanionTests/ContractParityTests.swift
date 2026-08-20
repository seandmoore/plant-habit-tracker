import XCTest
@testable import PlantCompanion

/// Replays the shared golden vectors through this app's planner and checks the rule tables and
/// generated catalog against `Contract/`. If a care rule changes in only one of the three
/// codebases, this fails.
final class ContractParityTests: XCTestCase {

    // MARK: - Contract loading

    /// Locates `Contract/` relative to this source file. Tests run on the machine that built
    /// them, so the checkout is present; if it is not, the test skips rather than failing for
    /// the wrong reason.
    private func contractURL(_ name: String) throws -> URL {
        let repositoryRoot = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = repositoryRoot.appending(path: "Contract").appending(path: name)

        guard FileManager.default.fileExists(atPath: url.path()) else {
            throw XCTSkip("Contract/\(name) is not reachable from \(url.path()); run these tests from a source checkout.")
        }
        return url
    }

    private func contract<Value: Decodable>(_ type: Value.Type, _ name: String) throws -> Value {
        let data = try Data(contentsOf: try contractURL(name))
        return try JSONDecoder().decode(Value.self, from: data)
    }

    // MARK: - Golden vectors

    private struct VectorDocument: Decodable {
        struct Vector: Decodable {
            struct Input: Decodable {
                let baselineWateringDays: Int
                let environment: PlantEnvironment
                let light: LightLevel
                let anchorDate: String
                let asOfDate: String
            }

            struct Expected: Decodable {
                let intervalDays: Int
                let dueDate: String
                let status: String
                let title: String
                let reason: String
            }

            let name: String
            let input: Input
            let expected: Expected
        }

        let vectors: [Vector]
    }

    func testPlannerReproducesEveryGoldenVector() throws {
        let document = try contract(VectorDocument.self, "recommendation-vectors.json")
        XCTAssertGreaterThanOrEqual(document.vectors.count, 13)

        // Vectors carry local calendar dates, so they stay timezone independent across
        // implementations as long as each one builds its dates from the components.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let planner = WateringPlanner(calendar: calendar)

        for vector in document.vectors {
            let profile = CareProfile(
                baselineWateringDays: vector.input.baselineWateringDays,
                environment: vector.input.environment,
                light: vector.input.light,
                anchor: try localDate(vector.input.anchorDate, calendar: calendar)
            )
            let plan = planner.plan(
                for: profile,
                plantID: UUID(),
                asOf: try localDate(vector.input.asOfDate, calendar: calendar)
            )

            XCTAssertEqual(plan.intervalDays, vector.expected.intervalDays, vector.name)
            XCTAssertEqual(statusName(plan.status), vector.expected.status, vector.name)
            XCTAssertEqual(plan.title, vector.expected.title, vector.name)
            XCTAssertEqual(plan.reason, vector.expected.reason, vector.name)
            XCTAssertEqual(dateString(plan.dueDate, calendar: calendar), vector.expected.dueDate, vector.name)
        }
    }

    // MARK: - Rule tables

    private struct RulesDocument: Decodable {
        struct Bounds: Decodable {
            let minimumIntervalDays: Int
            let maximumIntervalDays: Int
        }

        struct Modifier: Decodable {
            let key: String
            let days: Int
            let factor: String?
        }

        struct SeasonModifier: Decodable {
            let key: String
            let months: [Int]
            let days: Int
            let factor: String?
            let excludesEnvironments: [PlantEnvironment]
        }

        struct Phrasing: Decodable {
            let overdueTitle: String
            let dueTodayTitle: String
            let upcomingTitleTemplate: String
            let explanationWithoutFactors: String
            let explanationTemplate: String
            let reasonSuffix: String
        }

        let version: Int
        let bounds: Bounds
        let environmentModifiers: [Modifier]
        let lightModifiers: [Modifier]
        let seasonModifiers: [SeasonModifier]
        let seasonPrecedence: [String]
        let phrasing: Phrasing
    }

    func testCareRulesMatchTheContract() throws {
        let rules = try contract(RulesDocument.self, "care-rules.json")

        XCTAssertEqual(CareRules.version, rules.version)
        XCTAssertEqual(CareRules.minimumIntervalDays, rules.bounds.minimumIntervalDays)
        XCTAssertEqual(CareRules.maximumIntervalDays, rules.bounds.maximumIntervalDays)

        XCTAssertEqual(CareRules.environmentModifiers.map { $0.key.rawValue }, rules.environmentModifiers.map(\.key))
        XCTAssertEqual(CareRules.environmentModifiers.map(\.days), rules.environmentModifiers.map(\.days))
        XCTAssertEqual(CareRules.environmentModifiers.map(\.factor), rules.environmentModifiers.map(\.factor))

        XCTAssertEqual(CareRules.lightModifiers.map { $0.key.rawValue }, rules.lightModifiers.map(\.key))
        XCTAssertEqual(CareRules.lightModifiers.map(\.days), rules.lightModifiers.map(\.days))
        XCTAssertEqual(CareRules.lightModifiers.map(\.factor), rules.lightModifiers.map(\.factor))
    }

    func testSeasonModifiersMatchTheContractAndStayInPrecedenceOrder() throws {
        let rules = try contract(RulesDocument.self, "care-rules.json")

        XCTAssertEqual(CareRules.seasonModifiers.map(\.key), rules.seasonPrecedence)
        XCTAssertEqual(CareRules.seasonModifiers.map(\.key), rules.seasonModifiers.map(\.key))
        XCTAssertEqual(CareRules.seasonModifiers.map(\.months), rules.seasonModifiers.map(\.months))
        XCTAssertEqual(CareRules.seasonModifiers.map(\.days), rules.seasonModifiers.map(\.days))
        XCTAssertEqual(CareRules.seasonModifiers.map(\.factor), rules.seasonModifiers.map(\.factor))
        XCTAssertEqual(
            CareRules.seasonModifiers.map(\.excludedEnvironments),
            rules.seasonModifiers.map(\.excludesEnvironments)
        )
    }

    func testPhrasingMatchesTheContract() throws {
        let phrasing = try contract(RulesDocument.self, "care-rules.json").phrasing

        XCTAssertEqual(CareRules.Phrasing.overdueTitle, phrasing.overdueTitle)
        XCTAssertEqual(CareRules.Phrasing.dueTodayTitle, phrasing.dueTodayTitle)
        XCTAssertEqual(CareRules.Phrasing.explanationWithoutFactors, phrasing.explanationWithoutFactors)
        XCTAssertEqual(CareRules.Phrasing.reasonSuffix, phrasing.reasonSuffix)

        XCTAssertEqual(
            CareRules.Phrasing.upcomingTitle(days: 3),
            phrasing.upcomingTitleTemplate.replacingOccurrences(of: "{days}", with: "3").replacingOccurrences(of: "{plural}", with: "s")
        )
        XCTAssertEqual(
            CareRules.Phrasing.upcomingTitle(days: 1),
            phrasing.upcomingTitleTemplate.replacingOccurrences(of: "{days}", with: "1").replacingOccurrences(of: "{plural}", with: "")
        )
        XCTAssertEqual(
            CareRules.Phrasing.explanation(factors: ["kept indoors"]),
            phrasing.explanationTemplate.replacingOccurrences(of: "{factors}", with: "kept indoors")
        )
    }

    // MARK: - Catalog

    private struct CatalogDocument: Decodable {
        let version: Int
        let species: [PlantSpecies]
    }

    func testStarterCatalogMatchesTheContract() throws {
        let document = try contract(CatalogDocument.self, "catalog.json")

        XCTAssertEqual(StarterCatalog.version, document.version)
        XCTAssertEqual(StarterCatalog.species, document.species, "Run Scripts/sync-swift-catalog.mjs")
    }

    func testEveryCatalogBaselineStaysInsideThePlannerBounds() {
        for species in StarterCatalog.species {
            XCTAssertGreaterThanOrEqual(species.baselineWateringDays, CareRules.minimumIntervalDays, species.id)
            XCTAssertLessThanOrEqual(species.baselineWateringDays, CareRules.maximumIntervalDays, species.id)
        }
    }

    func testCatalogIdentifiersAreUnique() {
        XCTAssertEqual(Set(StarterCatalog.species.map(\.id)).count, StarterCatalog.species.count)
    }

    // MARK: - Helpers

    private func localDate(_ value: String, calendar: Calendar) throws -> Date {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            throw XCTSkip("Malformed contract date \(value)")
        }
        return try XCTUnwrap(
            calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        )
    }

    private func dateString(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private func statusName(_ status: CareRecommendation.Status) -> String {
        switch status {
        case .overdue: "overdue"
        case .dueToday: "dueToday"
        case .upcoming: "upcoming"
        }
    }
}
