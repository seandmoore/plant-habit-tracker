import XCTest
@testable import PlantCompanion

/// Exercises the planner directly through `CareProfile`, so no SwiftData container is involved.
final class WateringPlannerTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)
    private var planner = WateringPlanner()

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        planner = WateringPlanner(calendar: calendar)
    }

    // MARK: - Interval

    func testOutdoorContainerInDirectSummerSunDriesFastest() throws {
        let date = try XCTUnwrap(date(2026, 7, 10))
        let applied = planner.interval(
            for: profile(environment: .outdoorContainer, light: .direct, anchor: date),
            asOf: date
        )

        XCTAssertEqual(applied.days, 4)
        XCTAssertEqual(applied.factors, [
            "an outdoor pot can dry faster",
            "direct sun can dry soil faster",
            "it is the warmer part of the year"
        ])
    }

    func testLowLightIndoorPlantStretchesInWinter() throws {
        let date = try XCTUnwrap(date(2026, 12, 1))
        let applied = planner.interval(for: profile(light: .low, anchor: date), asOf: date)

        XCTAssertEqual(applied.days, 14)
    }

    func testMediumLightContributesNoExplanation() throws {
        let date = try XCTUnwrap(date(2026, 3, 1))
        let applied = planner.interval(for: profile(anchor: date), asOf: date)

        XCTAssertEqual(applied.days, 10)
        XCTAssertEqual(applied.factors, ["kept indoors"])
    }

    func testIndoorPlantsNeverReceiveTheWarmSeasonModifier() throws {
        let date = try XCTUnwrap(date(2026, 7, 15))
        let applied = planner.interval(
            for: profile(baselineWateringDays: 7, light: .direct, anchor: date),
            asOf: date
        )

        XCTAssertEqual(applied.days, 5)
        XCTAssertFalse(applied.factors.contains("it is the warmer part of the year"))
    }

    func testAtMostOneSeasonModifierApplies() throws {
        let date = try XCTUnwrap(date(2026, 6, 20))
        let applied = planner.interval(
            for: profile(baselineWateringDays: 6, environment: .outdoorContainer, anchor: date),
            asOf: date
        )

        let seasonFactors = applied.factors.filter { $0.contains("year") || $0.contains("cooler") }
        XCTAssertEqual(seasonFactors.count, 1)
    }

    func testIntervalIsClampedInBothDirections() throws {
        let summer = try XCTUnwrap(date(2026, 7, 1))
        let winter = try XCTUnwrap(date(2026, 12, 1))

        let floored = planner.interval(
            for: profile(baselineWateringDays: 1, environment: .outdoorContainer, light: .direct, anchor: summer),
            asOf: summer
        )
        let capped = planner.interval(
            for: profile(baselineWateringDays: 45, environment: .outdoorGround, light: .low, anchor: winter),
            asOf: winter
        )

        XCTAssertEqual(floored.days, CareRules.minimumIntervalDays)
        XCTAssertEqual(capped.days, CareRules.maximumIntervalDays)
    }

    func testNonsensicalBaselineIsTreatedAsTheMinimum() throws {
        let date = try XCTUnwrap(date(2026, 3, 1))
        let applied = planner.interval(for: profile(baselineWateringDays: 0, anchor: date), asOf: date)

        XCTAssertEqual(applied.days, 1)
    }

    // MARK: - Status and wording

    func testStatusReflectsHowFarTheDueDateIs() throws {
        let today = try XCTUnwrap(date(2026, 3, 20))

        let overdue = planner.plan(for: profile(anchor: try XCTUnwrap(date(2026, 3, 1))), plantID: UUID(), asOf: today)
        let dueToday = planner.plan(for: profile(anchor: try XCTUnwrap(date(2026, 3, 10))), plantID: UUID(), asOf: today)
        let upcoming = planner.plan(for: profile(anchor: try XCTUnwrap(date(2026, 3, 12))), plantID: UUID(), asOf: today)

        XCTAssertEqual(overdue.status, .overdue)
        XCTAssertEqual(overdue.title, "Check soil now")
        XCTAssertEqual(dueToday.status, .dueToday)
        XCTAssertEqual(dueToday.title, "Check soil today")
        XCTAssertEqual(upcoming.status, .upcoming)
        XCTAssertEqual(upcoming.title, "Check soil in 2 days")
    }

    func testSingularDayPhraseExactlyOneDayOut() throws {
        let plan = planner.plan(
            for: profile(anchor: try XCTUnwrap(date(2026, 3, 11))),
            plantID: UUID(),
            asOf: try XCTUnwrap(date(2026, 3, 20))
        )

        XCTAssertEqual(plan.title, "Check soil in 1 day")
    }

    func testEveryRecommendationAsksPeopleToCheckTheSoilThemselves() throws {
        let date = try XCTUnwrap(date(2026, 3, 1))
        let plan = planner.plan(for: profile(anchor: date), plantID: UUID(), asOf: date)

        XCTAssertTrue(plan.reason.hasSuffix("Feel the soil before watering."))
    }

    func testOnlyOverdueAndDueTodayNeedAttention() throws {
        let today = try XCTUnwrap(date(2026, 3, 20))
        let overdue = planner.plan(for: profile(anchor: try XCTUnwrap(date(2026, 3, 1))), plantID: UUID(), asOf: today)
        let upcoming = planner.plan(for: profile(anchor: try XCTUnwrap(date(2026, 3, 19))), plantID: UUID(), asOf: today)

        XCTAssertTrue(overdue.needsAttention)
        XCTAssertFalse(upcoming.needsAttention)
    }

    func testStatusOrdersMostUrgentFirst() {
        XCTAssertLessThan(CareRecommendation.Status.overdue, CareRecommendation.Status.dueToday)
        XCTAssertLessThan(CareRecommendation.Status.dueToday, CareRecommendation.Status.upcoming)
    }

    // MARK: - Helpers

    private func profile(
        baselineWateringDays: Int = 10,
        environment: PlantEnvironment = .indoor,
        light: LightLevel = .medium,
        anchor: Date
    ) -> CareProfile {
        CareProfile(
            baselineWateringDays: baselineWateringDays,
            environment: environment,
            light: light,
            anchor: anchor
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
