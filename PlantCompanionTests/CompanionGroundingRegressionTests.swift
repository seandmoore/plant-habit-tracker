import SwiftData
import XCTest
@testable import PlantCompanion

@MainActor
final class CompanionGroundingRegressionTests: XCTestCase {
    func testScriptedCompanionIncludesNextCareRecommendationFromPlantFacts() async throws {
        let fixture = try GroundingFixture()
        let facts = CompanionConversation.facts(for: fixture.plant, recommendation: fixture.recommendation)

        let response = try await ScriptedCompanionService().respond(to: CompanionPrompt(
            question: "When is the next care check?",
            plantName: fixture.plant.nickname,
            groundedFacts: facts
        ))

        XCTAssertTrue(response.contains(fixture.recommendation.title))
        XCTAssertTrue(response.contains(fixture.recommendation.reason))
        XCTAssertTrue(facts.allSatisfy { response.contains($0) }, "The fallback should retain the complete small set of saved facts")
    }

    func testScriptedCompanionIncludesLatestWateringDateFromPlantFacts() async throws {
        let fixture = try GroundingFixture()
        let facts = CompanionConversation.facts(for: fixture.plant, recommendation: fixture.recommendation)
        let latestWatering = try XCTUnwrap(fixture.plant.lastWateredAt)

        let response = try await ScriptedCompanionService().respond(to: CompanionPrompt(
            question: "When did I last water this plant?",
            plantName: fixture.plant.nickname,
            groundedFacts: facts
        ))

        XCTAssertTrue(response.contains(latestWatering.formatted(date: .abbreviated, time: .omitted)))
        XCTAssertTrue(facts.allSatisfy { response.contains($0) })
        XCTAssertTrue(response.contains("not a command"), "Including saved dates must preserve the reminder guardrail")
    }
}

/// Uses the real model, planner, and fact builder, with isolated storage and fixed dates.
@MainActor
private struct GroundingFixture {
    let container: ModelContainer
    let plant: UserPlant
    let recommendation: CareRecommendation

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let added = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 12)))
        let watered = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12)))
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 12)))

        container = try ModelContainer(
            for: UserPlant.self, CareEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        plant = UserPlant(
            nickname: "Moss",
            species: try XCTUnwrap(StarterCatalog.species.first),
            environment: .indoor,
            light: .medium,
            dateAdded: added
        )
        container.mainContext.insert(plant)
        let event = CareEvent(kind: .watered, timestamp: watered)
        container.mainContext.insert(event)
        plant.careEvents.append(event)
        try container.mainContext.save()

        recommendation = WateringPlanner(calendar: calendar).plan(for: plant.careProfile, plantID: plant.id, asOf: today)
    }
}
