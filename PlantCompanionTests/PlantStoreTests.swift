import SwiftData
import XCTest
@testable import PlantCompanion

/// Records what the store asked for, so reminder side effects can be asserted without touching
/// the real notification centre.
actor RecordingNotificationScheduler: NotificationScheduling {
    private(set) var scheduled: [WateringReminderRequest] = []
    private(set) var cancelled: [UUID] = []
    private let authorizationResult: Bool

    init(authorized: Bool = true) {
        authorizationResult = authorized
    }

    func requestAuthorization() async throws -> Bool { authorizationResult }

    func scheduleWateringReminder(_ request: WateringReminderRequest) async throws {
        scheduled.append(request)
    }

    func cancelWateringReminder(for plantID: UUID) async {
        cancelled.append(plantID)
    }
}

/// Everything one test needs, built fresh so no state leaks between them.
///
/// Built by a helper rather than in `setUp` because this suite is `@MainActor`, and a
/// MainActor-isolated override of XCTest's nonisolated setup is an isolation mismatch.
@MainActor
private struct Fixture {
    let container: ModelContainer
    let notifications: RecordingNotificationScheduler
    let store: PlantStore

    init(persist: @escaping (ModelContext) throws -> Void = { try $0.save() }) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        container = try ModelContainer(
            for: UserPlant.self, CareEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        notifications = RecordingNotificationScheduler()
        store = PlantStore(
            context: container.mainContext,
            planner: WateringPlanner(calendar: calendar),
            notifications: notifications,
            persist: persist
        )
    }

    @discardableResult
    func addPlant(
        nickname: String = "Moss",
        baselineWateringDays: Int = 10,
        environment: PlantEnvironment = .indoor,
        light: LightLevel = .medium,
        locationName: String = "",
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        notes: String = ""
    ) -> UserPlant {
        store.addPlant(
            nickname: nickname,
            species: Fixture.species(baselineWateringDays: baselineWateringDays),
            environment: environment,
            light: light,
            locationName: locationName,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            notes: notes
        )!
    }

    static func species(baselineWateringDays: Int = 10) -> PlantSpecies {
        PlantSpecies(
            id: "test",
            commonName: "Test plant",
            scientificName: "Planta testii",
            summary: "",
            baselineWateringDays: baselineWateringDays,
            light: "",
            soil: "",
            humidity: "",
            environments: [.indoor, .outdoorContainer, .outdoorGround],
            toxicityNote: nil,
            symbolName: "leaf.fill"
        )
    }
}

@MainActor
final class PlantStoreTests: XCTestCase {

    // MARK: - Writing

    func testAddingAPlantPersistsItWithTheSpeciesBaseline() throws {
        let fixture = try Fixture()

        let plant = fixture.addPlant(
            nickname: "  Moss  ",
            baselineWateringDays: 9,
            locationName: "  Living room  ",
            notes: "  A note  "
        )

        XCTAssertEqual(try fixture.container.mainContext.fetch(FetchDescriptor<UserPlant>()).count, 1)
        XCTAssertEqual(plant.baselineWateringDays, 9)
        XCTAssertEqual(plant.nickname, "Moss")
        XCTAssertEqual(plant.locationName, "Living room")
        XCTAssertEqual(plant.notes, "A note")
        XCTAssertNil(fixture.store.lastError)
    }

    func testAddingAPlantWithoutANicknameFallsBackToTheCommonName() throws {
        let fixture = try Fixture()

        XCTAssertEqual(fixture.addPlant(nickname: "   ").nickname, "Test plant")
    }

    func testLoggingWateringAppendsAnEventAndPersistsIt() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()

        fixture.store.logWatering(for: plant, amount: 250, unit: .milliliters, note: "  Soil was dry  ")

        XCTAssertEqual(try fixture.container.mainContext.fetch(FetchDescriptor<CareEvent>()).count, 1)
        XCTAssertEqual(plant.careEvents.first?.amount, 250)
        XCTAssertEqual(plant.careEvents.first?.waterUnit, .milliliters)
        XCTAssertEqual(plant.careEvents.first?.note, "Soil was dry")
        XCTAssertEqual(plant.careEvents.first?.measurement, "250 mL")
    }

    func testAUnitIsNotRecordedWithoutAnAmount() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()

        fixture.store.logWatering(for: plant, amount: nil, unit: .milliliters)

        XCTAssertNil(plant.careEvents.first?.amount)
        XCTAssertNil(plant.careEvents.first?.waterUnit)
        XCTAssertNil(plant.careEvents.first?.measurement)
    }

    func testDeletingAPlantCascadesItsCareHistory() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()
        fixture.store.logWatering(for: plant)

        fixture.store.delete(plant)

        XCTAssertTrue(try fixture.container.mainContext.fetch(FetchDescriptor<UserPlant>()).isEmpty)
        XCTAssertTrue(try fixture.container.mainContext.fetch(FetchDescriptor<CareEvent>()).isEmpty, "Failed watering must remove the inserted event")
    }

    func testCommittingEditsFallsBackToTheCommonNameWhenTheNicknameIsCleared() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()

        plant.nickname = "   "
        fixture.store.commitEdits(to: plant)

        XCTAssertEqual(plant.nickname, "Test plant")
    }

    func testCareHistoryIsOrderedNewestFirst() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()
        let now = Date.now

        fixture.store.logWatering(for: plant, timestamp: now.addingTimeInterval(-20 * 86_400), note: "older")
        fixture.store.logWatering(for: plant, timestamp: now.addingTimeInterval(-2 * 86_400), note: "newer")

        XCTAssertEqual(plant.sortedCareEvents.map(\.note), ["newer", "older"])
    }

    // MARK: - Derivations

    func testCareQueueOrdersOverdueFirstThenByDueDate() throws {
        let fixture = try Fixture()
        let overdue = fixture.addPlant(nickname: "Overdue")
        let upcoming = fixture.addPlant(nickname: "Upcoming")
        let dueToday = fixture.addPlant(nickname: "Due today")
        let now = Date.now

        fixture.store.logWatering(for: overdue, timestamp: now.addingTimeInterval(-40 * 86_400))
        fixture.store.logWatering(for: dueToday, timestamp: now.addingTimeInterval(-10 * 86_400))
        fixture.store.logWatering(for: upcoming, timestamp: now)

        let queue = fixture.store.careQueue([overdue, upcoming, dueToday], asOf: now)

        XCTAssertEqual(queue.map(\.plant.nickname), ["Overdue", "Due today", "Upcoming"])
        XCTAssertEqual(queue.first?.recommendation.status, .overdue)
        XCTAssertEqual(queue.last?.recommendation.status, .upcoming)
    }

    func testTheScheduleAnchorsToTheMostRecentWatering() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()
        let now = Date.now

        fixture.store.logWatering(for: plant, timestamp: now.addingTimeInterval(-20 * 86_400))
        fixture.store.logWatering(for: plant, timestamp: now.addingTimeInterval(-2 * 86_400))

        XCTAssertEqual(fixture.store.recommendation(for: plant, asOf: now).status, .upcoming)
    }

    func testWateringCountOnlyCountsWateringsInsideTheWindow() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()
        let now = Date.now

        fixture.store.logWatering(for: plant, timestamp: now.addingTimeInterval(-2 * 86_400))
        fixture.store.logWatering(for: plant, timestamp: now.addingTimeInterval(-30 * 86_400))

        XCTAssertEqual(fixture.store.wateringCount(in: [plant], days: 7, asOf: now), 1)
    }

    func testCareProfileIgnoresEventsThatAreNotWaterings() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()

        let pruning = CareEvent(kind: .pruned, timestamp: .now)
        fixture.container.mainContext.insert(pruning)
        plant.careEvents.append(pruning)

        XCTAssertNil(plant.lastWateredAt)
        XCTAssertEqual(plant.careProfile.anchor, plant.dateAdded)
    }

    func testSearchMatchesNicknameCommonAndScientificNames() throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()

        XCTAssertTrue(plant.matches(query: "moss"))
        XCTAssertTrue(plant.matches(query: "Test plant"))
        XCTAssertTrue(plant.matches(query: "planta"))
        XCTAssertTrue(plant.matches(query: "   "))
        XCTAssertFalse(plant.matches(query: "zzz"))
    }

    // MARK: - Reminders

    func testEnablingAReminderSchedulesItForTheRecommendedDate() async throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant(reminderEnabled: true, reminderHour: 8)

        try await Task.sleep(for: .milliseconds(150))

        let scheduled = await fixture.notifications.scheduled
        XCTAssertEqual(scheduled.count, 1)
        XCTAssertEqual(scheduled.first?.plantID, plant.id)
        XCTAssertEqual(scheduled.first?.hour, 8)
        XCTAssertEqual(scheduled.first?.dueDate, fixture.store.recommendation(for: plant).dueDate)
    }

    func testAPlantWithRemindersOffIsCancelledRatherThanScheduled() async throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant()

        try await Task.sleep(for: .milliseconds(150))

        let scheduled = await fixture.notifications.scheduled
        let cancelled = await fixture.notifications.cancelled
        XCTAssertTrue(scheduled.isEmpty)
        XCTAssertEqual(cancelled, [plant.id])
    }

    /// The schedule is anchored to the newest watering, so the reminder has to move with it.
    func testLoggingWateringReschedulesTheReminder() async throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant(reminderEnabled: true)

        try await Task.sleep(for: .milliseconds(150))
        fixture.store.logWatering(for: plant)
        try await Task.sleep(for: .milliseconds(150))

        let scheduled = await fixture.notifications.scheduled
        XCTAssertEqual(scheduled.count, 2)
        XCTAssertNotEqual(scheduled.first?.dueDate, scheduled.last?.dueDate)
    }

    func testDeletingAPlantCancelsItsReminder() async throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant(reminderEnabled: true)
        let id = plant.id

        fixture.store.delete(plant)
        try await Task.sleep(for: .milliseconds(150))

        let cancelled = await fixture.notifications.cancelled
        XCTAssertTrue(cancelled.contains(id))
    }

    func testADeclinedAuthorizationDoesNotBlockSavedCare() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let container = try ModelContainer(
            for: UserPlant.self, CareEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let notifications = RecordingNotificationScheduler(authorized: false)
        let store = PlantStore(
            context: container.mainContext,
            planner: WateringPlanner(calendar: calendar),
            notifications: notifications
        )

        let plant = store.addPlant(
            nickname: "Moss",
            species: Fixture.species(),
            environment: .indoor,
            light: .medium,
            reminderEnabled: true
        )!
        try await Task.sleep(for: .milliseconds(150))

        let scheduled = await notifications.scheduled
        XCTAssertTrue(scheduled.isEmpty)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<UserPlant>()).count, 1)
        XCTAssertNil(store.lastError)
        XCTAssertEqual(plant.nickname, "Moss")
    }
}


/// A deterministic authorization gate, with final pending state rather than call counts.
private actor SuspendedNotificationScheduler: NotificationScheduling {
    private var authorization: CheckedContinuation<Bool, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private(set) var pending: [UUID: WateringReminderRequest] = [:]

    func requestAuthorization() async throws -> Bool {
        await withCheckedContinuation { continuation in
            authorization = continuation
            started?.resume()
            started = nil
        }
    }

    func waitUntilAuthorizationStarts() async {
        if authorization != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func authorize() {
        authorization?.resume(returning: true)
        authorization = nil
    }

    func scheduleWateringReminder(_ request: WateringReminderRequest) async throws {
        pending[request.plantID] = request
    }

    func cancelWateringReminder(for plantID: UUID) async { pending[plantID] = nil }
}

@MainActor
final class PlantStoreRegressionTests: XCTestCase {
    private enum SaveFailure: Error { case injected }

    func testFailedAddReturnsNilRollsBackAndDoesNotSchedule() async throws {
        let fixture = try Fixture(persist: { _ in throw SaveFailure.injected })
        let plant = fixture.store.addPlant(
            nickname: "Fern", species: Fixture.species(), environment: .indoor,
            light: .medium, reminderEnabled: true
        )
        XCTAssertNil(plant)
        XCTAssertNotNil(fixture.store.lastError)
        XCTAssertTrue(try fixture.container.mainContext.fetch(FetchDescriptor<UserPlant>()).isEmpty)
        let scheduled = await fixture.notifications.scheduled
        XCTAssertTrue(scheduled.isEmpty)
    }

    func testFailedWateringEditAndDeleteRollBackWithoutReminderSideEffects() async throws {
        var fail = false
        let fixture = try Fixture(persist: { context in
            if fail { throw SaveFailure.injected }
            try context.save()
        })
        let plant = fixture.addPlant(reminderEnabled: true)
        await fixture.store.waitForReminderOperations(for: plant.id)
        XCTAssertTrue(fixture.store.logWatering(for: plant, note: "Saved history"))
        await fixture.store.waitForReminderOperations(for: plant.id)
        fail = true
        XCTAssertFalse(fixture.store.logWatering(for: plant))
        XCTAssertEqual(plant.careEvents.map(\.note), ["Saved history"], "Failed watering must restore the plant relationship")
        XCTAssertEqual(try fixture.container.mainContext.fetch(FetchDescriptor<CareEvent>()).count, 1, "Failed watering must remove only the inserted event")
        XCTAssertNotNil(fixture.store.lastError)

        var edits = PlantEdits(plant: plant)
        edits.nickname = "Changed"
        edits.reminderEnabled = false
        XCTAssertFalse(fixture.store.commitEdits(to: plant, edits: edits))
        XCTAssertEqual(plant.nickname, "Moss")
        XCTAssertTrue(plant.reminderEnabled, "Failed or discarded edits must preserve reminder enablement")
        XCTAssertFalse(fixture.store.delete(plant))
        XCTAssertEqual(try fixture.container.mainContext.fetch(FetchDescriptor<UserPlant>()).count, 1)
        await fixture.store.waitForReminderOperations(for: plant.id)
        let scheduled = await fixture.notifications.scheduled
        let cancelled = await fixture.notifications.cancelled
        XCTAssertEqual(scheduled.count, 2)
        XCTAssertEqual(plant.careEvents.map(\.note), ["Saved history"], "Failed deletion must restore care history")
        let reloaded = try ModelContext(fixture.container).fetch(FetchDescriptor<UserPlant>())
        XCTAssertEqual(reloaded.first?.careEvents.count, 1, "Persisted history must survive failed writes")
        XCTAssertTrue(cancelled.isEmpty, "Failed writes must not cancel the saved reminder")

        fail = false
        XCTAssertTrue(fixture.store.logWatering(for: plant), "Retry after restoring persistence must succeed")
        XCTAssertEqual(plant.careEvents.count, 2)
        XCTAssertNil(fixture.store.lastError)
        await fixture.store.waitForReminderOperations(for: plant.id)
    }

    func testDiscardingEditDraftLeavesModelAndReminderUnchanged() async throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant(reminderEnabled: true, reminderHour: 9)
        await fixture.store.waitForReminderOperations(for: plant.id)
        var draft = PlantEdits(plant: plant)
        draft.nickname = "Discarded"
        draft.reminderEnabled = false
        draft.reminderHour = 20
        // Cancel and interactive dismissal both discard this value without committing it.
        XCTAssertEqual(plant.nickname, "Moss")
        XCTAssertTrue(plant.reminderEnabled, "Failed or discarded edits must preserve reminder enablement")
        XCTAssertEqual(plant.reminderHour, 9)
        XCTAssertFalse(fixture.container.mainContext.hasChanges)
        let scheduled = await fixture.notifications.scheduled
        XCTAssertEqual(scheduled.count, 1)
        XCTAssertEqual(scheduled.first?.hour, 9)
        XCTAssertEqual(draft.reminderHour, 20)
    }

    func testCommittingDraftUpdatesModelAndReminder() async throws {
        let fixture = try Fixture()
        let plant = fixture.addPlant(reminderEnabled: true)
        await fixture.store.waitForReminderOperations(for: plant.id)
        var draft = PlantEdits(plant: plant)
        draft.reminderHour = 20
        XCTAssertTrue(fixture.store.commitEdits(to: plant, edits: draft))
        await fixture.store.waitForReminderOperations(for: plant.id)
        let scheduled = await fixture.notifications.scheduled
        XCTAssertEqual(scheduled.last?.hour, 20)
        draft.reminderEnabled = false
        XCTAssertTrue(fixture.store.commitEdits(to: plant, edits: draft))
        await fixture.store.waitForReminderOperations(for: plant.id)
        let cancelled = await fixture.notifications.cancelled
        XCTAssertEqual(cancelled, [plant.id])
    }

    func testDeletingDuringAuthorizationCannotResurrectReminder() async throws {
        try await assertNoStaleReminder(delete: true)
    }

    func testDisablingDuringAuthorizationCannotResurrectReminder() async throws {
        try await assertNoStaleReminder(delete: false)
    }

    private func assertNoStaleReminder(delete: Bool) async throws {
        let container = try ModelContainer(
            for: UserPlant.self, CareEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let notifications = SuspendedNotificationScheduler()
        let store = PlantStore(context: container.mainContext, notifications: notifications)
        let plant = try XCTUnwrap(store.addPlant(
            nickname: "Fern", species: Fixture.species(), environment: .indoor,
            light: .medium, reminderEnabled: true
        ))
        let id = plant.id
        await notifications.waitUntilAuthorizationStarts()
        if delete {
            XCTAssertTrue(store.delete(plant))
        } else {
            var draft = PlantEdits(plant: plant)
            draft.reminderEnabled = false
            XCTAssertTrue(store.commitEdits(to: plant, edits: draft))
        }
        await notifications.authorize()
        await store.waitForReminderOperations(for: id)
        let pending = await notifications.pending
        XCTAssertTrue(pending.isEmpty)
    }
}


private actor SuspendedAddScheduler: NotificationScheduling {
    private var add: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private(set) var pending: Set<UUID> = []

    func requestAuthorization() async throws -> Bool { true }
    func scheduleWateringReminder(_ request: WateringReminderRequest) async throws {
        await withCheckedContinuation { continuation in
            add = continuation
            started?.resume()
            started = nil
        }
        pending.insert(request.plantID)
    }
    func waitUntilAddStarts() async {
        if add != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func finishAdd() { add?.resume(); add = nil }
    func cancelWateringReminder(for plantID: UUID) async { pending.remove(plantID) }
}

extension PlantStoreRegressionTests {
    func testDeletingDuringNotificationAddCancelsAfterAddFinishes() async throws {
        let container = try ModelContainer(
            for: UserPlant.self, CareEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let notifications = SuspendedAddScheduler()
        let store = PlantStore(context: container.mainContext, notifications: notifications)
        let plant = try XCTUnwrap(store.addPlant(
            nickname: "Fern", species: Fixture.species(), environment: .indoor,
            light: .medium, reminderEnabled: true
        ))
        let id = plant.id
        await notifications.waitUntilAddStarts()
        XCTAssertTrue(store.delete(plant))
        await notifications.finishAdd()
        await store.waitForReminderOperations(for: id)
        let pending = await notifications.pending
        XCTAssertTrue(pending.isEmpty)
    }
}
