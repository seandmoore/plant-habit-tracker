import SwiftData
import XCTest
@testable import PlantCompanion

final class SeasonalPlannerRegressionTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testASeasonChangeDoesNotMoveTheDateOrExplanationForAnExistingCycle() throws {
        let planner = WateringPlanner(calendar: calendar)
        let cases: [(Int, Int, PlantEnvironment, LightLevel, Int, Int, Int)] = [
            (10, 24, .indoor, .medium, 11, 2, 9),
            (2, 24, .indoor, .medium, 3, 7, 11),
            (5, 28, .outdoorContainer, .brightIndirect, 6, 3, 6),
            (8, 28, .outdoorContainer, .brightIndirect, 9, 1, 4)
        ]
        for (month, day, environment, light, dueMonth, dueDay, interval) in cases {
            let anchor = try date(month, day)
            let due = try date(dueMonth, dueDay)
            let profile = CareProfile(baselineWateringDays: 9, environment: environment, light: light, anchor: anchor)
            let id = UUID()
            let atStart = planner.plan(for: profile, plantID: id, asOf: anchor)
            let onDueDay = planner.plan(for: profile, plantID: id, asOf: due)
            let afterDueDay = planner.plan(for: profile, plantID: id, asOf: try XCTUnwrap(calendar.date(byAdding: .day, value: 2, to: due)))

            XCTAssertEqual(atStart.dueDate, due, "Cycle starting \(month)/\(day)")
            XCTAssertEqual(atStart.intervalDays, interval)
            XCTAssertEqual(onDueDay.dueDate, atStart.dueDate)
            XCTAssertEqual(onDueDay.intervalDays, atStart.intervalDays)
            XCTAssertEqual(onDueDay.reason, atStart.reason)
            XCTAssertEqual(onDueDay.status, .dueToday)
            XCTAssertEqual(afterDueDay.dueDate, due)
            XCTAssertEqual(afterDueDay.status, .overdue)
        }
    }

    func testNewWateringUsesTheNewSeason() throws {
        let planner = WateringPlanner(calendar: calendar)
        let old = CareProfile(baselineWateringDays: 9, environment: .indoor, light: .medium, anchor: try date(10, 24))
        let watered = CareProfile(baselineWateringDays: 9, environment: .indoor, light: .medium, anchor: try date(11, 2))
        let previousPlan = planner.plan(for: old, plantID: UUID(), asOf: try date(11, 2))
        let newPlan = planner.plan(for: watered, plantID: UUID(), asOf: try date(11, 2))

        XCTAssertEqual(previousPlan.intervalDays, 9)
        XCTAssertEqual(newPlan.intervalDays, 11)
        XCTAssertEqual(newPlan.dueDate, try date(11, 13))
        XCTAssertTrue(newPlan.reason.contains("cooler months"))
    }

    private func date(_ month: Int, _ day: Int) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day)))
    }
}

@MainActor
final class SeasonalReminderRegressionTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testScheduledRequestAgreesWithThePlanAfterTheSeasonChanges() async throws {
        let container = try memoryContainer()
        let notifications = RecordingNotificationScheduler()
        let store = PlantStore(context: container.mainContext, planner: WateringPlanner(calendar: calendar), notifications: notifications)
        let plant = try makePlant(anchorMonth: 10, anchorDay: 24, enabled: true)
        container.mainContext.insert(plant)
        try container.mainContext.save()

        store.refreshReminder(for: plant)
        await store.waitForReminderOperations(for: plant.id)
        let scheduled = await notifications.scheduled
        let request = try XCTUnwrap(scheduled.last)
        let laterPlan = store.recommendation(for: plant, asOf: try date(11, 2))
        XCTAssertEqual(request.dueDate, try date(11, 2))
        XCTAssertEqual(request.dueDate, laterPlan.dueDate)
        XCTAssertEqual(laterPlan.status, .dueToday)
        XCTAssertFalse(container.mainContext.hasChanges)
    }

    func testLaunchRestoresSavedOptInRemindersOnceWithoutChangingCareRecords() async throws {
        let container = try memoryContainer()
        let context = container.mainContext
        context.autosaveEnabled = false
        let enabled = try makePlant(anchorMonth: 2, anchorDay: 24, enabled: true)
        let disabled = try makePlant(anchorMonth: 2, anchorDay: 24, enabled: false)
        context.insert(enabled)
        context.insert(disabled)
        try context.save()
        let originalProfile = enabled.careProfile
        let originalName = enabled.nickname
        let originalNotes = enabled.notes

        let notifications = RecordingNotificationScheduler()
        // Simulates the pending request from the old algorithm, which used the later month.
        try await notifications.scheduleWateringReminder(WateringReminderRequest(
            plantID: enabled.id, plantName: enabled.nickname, dueDate: try date(3, 5), hour: 9
        ))
        var saves = 0
        let store = PlantStore(context: context, planner: WateringPlanner(calendar: calendar), notifications: notifications, persist: { _ in saves += 1 })
        store.restoreReminders()
        await store.waitForReminderOperations(for: enabled.id)
        store.restoreReminders()
        await store.waitForReminderOperations(for: enabled.id)

        let scheduled = await notifications.scheduled
        XCTAssertEqual(scheduled.count, 2, "One old request plus one replacement, even if multiple windows restore")
        XCTAssertEqual(scheduled.last?.plantID, enabled.id)
        XCTAssertEqual(scheduled.last?.dueDate, try date(3, 7))
        XCTAssertFalse(scheduled.contains { $0.plantID == disabled.id })
        XCTAssertEqual(saves, 0)
        XCTAssertEqual(enabled.careProfile, originalProfile)
        XCTAssertEqual(enabled.nickname, originalName)
        XCTAssertEqual(enabled.notes, originalNotes)
        XCTAssertTrue(enabled.careEvents.isEmpty)
        XCTAssertFalse(context.hasChanges)
    }

    func testLaunchDoesNotScheduleAnUnsavedPlant() async throws {
        let container = try memoryContainer()
        let context = container.mainContext
        context.autosaveEnabled = false
        let unsaved = try makePlant(anchorMonth: 10, anchorDay: 24, enabled: true)
        context.insert(unsaved)
        let notifications = RecordingNotificationScheduler()
        let store = PlantStore(context: context, planner: WateringPlanner(calendar: calendar), notifications: notifications)

        store.restoreReminders()
        await store.waitForReminderOperations(for: unsaved.id)

        let scheduled = await notifications.scheduled
        XCTAssertTrue(scheduled.isEmpty)
        XCTAssertTrue(context.hasChanges, "Restoration must not save a pending insert")
    }

    private func memoryContainer() throws -> ModelContainer {
        try ModelContainer(for: UserPlant.self, CareEvent.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func makePlant(anchorMonth: Int, anchorDay: Int, enabled: Bool) throws -> UserPlant {
        UserPlant(nickname: "Test Monstera", species: StarterCatalog.species[0], environment: .indoor, light: .medium,
                  dateAdded: try date(anchorMonth, anchorDay), reminderEnabled: enabled, notes: "Keep this note")
    }

    private func date(_ month: Int, _ day: Int) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day)))
    }
}
