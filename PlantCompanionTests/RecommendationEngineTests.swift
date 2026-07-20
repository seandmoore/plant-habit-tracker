import XCTest
@testable import PlantCompanion

final class RecommendationEngineTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testOutdoorContainerInDirectSummerSunShortensInterval() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 10)))
        let plant = makePlant(environment: .outdoorContainer, light: .direct, dateAdded: date)
        let result = DefaultRecommendationEngine(calendar: calendar).wateringRecommendation(for: plant, asOf: date)

        XCTAssertEqual(result.intervalDays, 4)
        XCTAssertEqual(result.status, .upcoming)
    }

    func testLowLightIndoorPlantGetsLongerWinterInterval() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 12, day: 1)))
        let plant = makePlant(environment: .indoor, light: .low, dateAdded: date)
        let result = DefaultRecommendationEngine(calendar: calendar).wateringRecommendation(for: plant, asOf: date)

        XCTAssertEqual(result.intervalDays, 14)
        XCTAssertTrue(result.reason.contains("Feel the soil"))
    }

    func testMostRecentWateringBecomesScheduleAnchor() throws {
        let added = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        let watered = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8)))
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 20)))
        let plant = makePlant(environment: .indoor, light: .medium, dateAdded: added)
        plant.careEvents.append(CareEvent(kind: .watered, timestamp: watered))

        let result = DefaultRecommendationEngine(calendar: calendar).wateringRecommendation(for: plant, asOf: today)

        XCTAssertEqual(result.status, .overdue)
        XCTAssertEqual(result.dueDate, try XCTUnwrap(calendar.date(byAdding: .day, value: 10, to: watered)))
    }

    private func makePlant(environment: PlantEnvironment, light: LightLevel, dateAdded: Date) -> UserPlant {
        UserPlant(
            nickname: "Test plant",
            species: PlantSpecies(
                id: "test", commonName: "Test plant", scientificName: "Planta testii", summary: "",
                baselineWateringDays: 10, light: "", soil: "", humidity: "",
                environments: [.indoor, .outdoorContainer, .outdoorGround], toxicityNote: nil, symbolName: "leaf"
            ),
            environment: environment,
            light: light,
            dateAdded: dateAdded
        )
    }
}
