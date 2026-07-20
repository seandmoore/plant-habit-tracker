import SwiftData
import XCTest
@testable import PlantCompanion

@MainActor
final class PersistenceTests: XCTestCase {
    func testPlantAndCareEventPersistInMemory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = makePlant()
        let event = CareEvent(kind: .watered, amount: 250, waterUnit: .milliliters, note: "Soil was dry")
        context.insert(plant)
        context.insert(event)
        plant.careEvents.append(event)
        try context.save()

        let plants = try context.fetch(FetchDescriptor<UserPlant>())
        let events = try context.fetch(FetchDescriptor<CareEvent>())

        XCTAssertEqual(plants.count, 1)
        XCTAssertEqual(plants.first?.careEvents.first?.amount, 250)
        XCTAssertEqual(events.first?.note, "Soil was dry")
    }

    func testDeletingPlantCascadesCareHistory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = makePlant()
        let event = CareEvent(kind: .watered)
        context.insert(plant)
        context.insert(event)
        plant.careEvents.append(event)
        try context.save()

        context.delete(plant)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<UserPlant>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: UserPlant.self, CareEvent.self, configurations: configuration)
    }

    private func makePlant() -> UserPlant {
        UserPlant(
            nickname: "Moss",
            species: PlantSpecies(
                id: "test", commonName: "Test", scientificName: "Planta testii", summary: "",
                baselineWateringDays: 7, light: "Bright", soil: "Draining", humidity: "Average",
                environments: [.indoor], toxicityNote: nil, symbolName: "leaf.fill"
            ),
            environment: .indoor,
            light: .brightIndirect
        )
    }
}
