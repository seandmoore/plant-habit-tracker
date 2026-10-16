import SwiftData
import XCTest
@testable import PlantCompanion

final class WaterAmountRegressionTests: XCTestCase {
    func testRejectsInfinitySpellings() {
        for input in ["inf", "+inf", "-inf", "infinity", "Infinity", "  INF  "] {
            XCTAssertNil(WaterAmount.parse(input), "Must not record a non-finite amount: \(input)")
        }
    }

    func testRejectsNumericOverflow() {
        for input in ["1e309", "9.99e999", "1,0e309"] {
            XCTAssertNil(WaterAmount.parse(input), "Overflow must not become an infinite amount: \(input)")
        }
    }

    func testRejectsNaN() {
        for input in ["nan", "NaN", "+nan", "  NaN  "] {
            XCTAssertNil(WaterAmount.parse(input))
        }
    }

    func testAcceptsFinitePositiveAmountsAndBothDecimalSeparators() {
        let examples: [(String, Double)] = [
            ("250", 250),
            ("12.5", 12.5),
            ("12,5", 12.5),
            ("  0,5\n", 0.5),
            ("1e3", 1_000),
            (String(Double.greatestFiniteMagnitude), Double.greatestFiniteMagnitude)
        ]
        for (input, expected) in examples {
            XCTAssertEqual(WaterAmount.parse(input), expected, "Valid amount must remain accepted: \(input)")
        }
    }

    @MainActor
    func testNonFiniteInputStillPersistsWateringWithoutAmountOrUnit() async throws {
        let container = try ModelContainer(
            for: UserPlant.self, CareEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let notifications = RecordingNotificationScheduler()
        let store = PlantStore(context: container.mainContext, notifications: notifications)
        let species = try XCTUnwrap(StarterCatalog.species.first)
        let plant = try XCTUnwrap(store.addPlant(
            nickname: "Amount regression", species: species,
            environment: .indoor, light: .medium, reminderEnabled: true
        ))
        let inputs = ["inf", "infinity", "1e309", "nan"]
        let wateredAt = Date(timeIntervalSince1970: 1_780_000_000)

        for input in inputs {
            // Match the watering sheet: an optional parsed amount and the selected unit.
            XCTAssertTrue(store.logWatering(
                for: plant, amount: WaterAmount.parse(input), unit: .milliliters,
                timestamp: wateredAt, note: input
            ))
        }

        let reloadContext = ModelContext(container)
        let reloadedPlant = try XCTUnwrap(reloadContext.fetch(FetchDescriptor<UserPlant>()).first)
        XCTAssertEqual(reloadedPlant.careEvents.count, inputs.count)
        XCTAssertEqual(Set(reloadedPlant.careEvents.map(\.note)), Set(inputs))
        for event in reloadedPlant.careEvents {
            XCTAssertEqual(event.kind, .watered)
            XCTAssertEqual(event.timestamp, wateredAt)
            XCTAssertNil(event.amount)
            XCTAssertNil(event.waterUnit)
            XCTAssertNil(event.measurement)
        }
        XCTAssertEqual(reloadedPlant.lastWateredAt, wateredAt)
        XCTAssertNil(store.lastError)
        await store.waitForReminderOperations(for: plant.id)
        let reminder = await notifications.scheduled.last
        XCTAssertEqual(reminder?.plantID, plant.id)
        XCTAssertEqual(reminder?.dueDate, store.recommendation(for: plant).dueDate)
        withExtendedLifetime(reloadContext) {}
    }
}
