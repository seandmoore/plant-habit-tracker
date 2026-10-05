import Foundation
import Observation
import SwiftData

/// The only place plants and care events are written.
///
/// Previously each screen ran the same four steps by hand — insert the event, append it to the
/// plant, save, then reschedule the reminder — which meant three copies that could drift and a
/// `try?` that swallowed save failures. Everything funnels through here instead, so a write and
/// its reminder side effect always happen together and a failure is reported rather than lost.
/// A plant together with the recommendation derived from it. Views render these instead of
/// recomputing recommendations inline, which is what keeps ordering consistent everywhere.
@MainActor
struct CareQueueEntry: Identifiable {
    let plant: UserPlant
    let recommendation: CareRecommendation

    nonisolated var id: UUID { recommendation.plantID }
}

@MainActor
@Observable
final class PlantStore {
    /// Set when a write fails, so a screen can tell someone their change did not stick.
    var lastError: String?

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let planner: WateringPlanner
    @ObservationIgnored private let notifications: any NotificationScheduling
    @ObservationIgnored private let persist: (ModelContext) throws -> Void
    @ObservationIgnored private var authorizationTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var reminderVersions: [UUID: Int] = [:]
    @ObservationIgnored private var reminderOperations: [UUID: Task<Void, Never>] = [:]

    init(
        context: ModelContext,
        planner: WateringPlanner = WateringPlanner(),
        notifications: any NotificationScheduling,
        persist: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.context = context
        self.planner = planner
        self.notifications = notifications
        self.persist = persist
    }

    // MARK: - Reading

    func recommendation(for plant: UserPlant, asOf date: Date = .now) -> CareRecommendation {
        planner.plan(for: plant.careProfile, plantID: plant.id, asOf: date)
    }

    /// Plants paired with their recommendation, most urgent first, then by due date. Every
    /// surface that lists plants reads this, so they cannot disagree about what is due.
    func careQueue(_ plants: [UserPlant], asOf date: Date = .now) -> [CareQueueEntry] {
        plants
            .map { CareQueueEntry(plant: $0, recommendation: recommendation(for: $0, asOf: date)) }
            .sorted { first, second in
                first.recommendation.status == second.recommendation.status
                    ? first.recommendation.dueDate < second.recommendation.dueDate
                    : first.recommendation.status < second.recommendation.status
            }
    }

    func wateringCount(in plants: [UserPlant], days: Int, asOf date: Date = .now) -> Int {
        let calendar = planner.calendar
        guard let start = calendar.date(byAdding: .day, value: -days, to: date) else { return 0 }
        return plants
            .flatMap(\.careEvents)
            .filter { $0.kind == .watered && $0.timestamp >= start }
            .count
    }

    // MARK: - Writing

    @discardableResult
    func addPlant(
        nickname: String,
        species: PlantSpecies,
        environment: PlantEnvironment,
        light: LightLevel,
        locationName: String = "",
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        notes: String = "",
        photoData: Data? = nil
    ) -> UserPlant? {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let plant = UserPlant(
            nickname: trimmedNickname.isEmpty ? species.commonName : trimmedNickname,
            species: species,
            environment: environment,
            light: light,
            locationName: locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData
        )
        context.insert(plant)
        guard save() else { return nil }
        refreshReminder(for: plant)
        return plant
    }

    @discardableResult
    func logWatering(
        for plant: UserPlant,
        amount: Double? = nil,
        unit: WaterUnit? = nil,
        timestamp: Date = .now,
        note: String = ""
    ) -> Bool {
        let previousEvents = plant.careEvents
        let event = CareEvent(
            kind: .watered,
            timestamp: timestamp,
            amount: amount,
            waterUnit: unit,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(event)
        plant.careEvents.append(event)
        guard save() else {
            // SwiftData rollback removes the inserted event but can leave the live
            // relationship cache holding it. Restore the pre-write collection too.
            plant.careEvents = previousEvents
            return false
        }
        // The schedule is anchored to the newest watering, so the reminder moves with it.
        refreshReminder(for: plant)
        return true
    }

    /// Applies a form draft, persists it, and only then re-times its reminder.
    @discardableResult
    func commitEdits(to plant: UserPlant, edits: PlantEdits? = nil) -> Bool {
        edits?.apply(to: plant)
        plant.nickname = plant.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if plant.nickname.isEmpty { plant.nickname = plant.commonName }
        guard save() else { return false }
        refreshReminder(for: plant)
        return true
    }

    @discardableResult
    func delete(_ plant: UserPlant) -> Bool {
        let id = plant.id
        let previousEvents = plant.careEvents
        context.delete(plant)
        guard save() else {
            plant.careEvents = previousEvents
            return false
        }
        reminderVersions[id, default: 0] += 1
        enqueueReminder(nil, for: id)
        return true
    }

    // MARK: - Reminders

    /// Reminders are always derived from the current recommendation, never scheduled ad hoc, so
    /// a plant can never hold a notification that disagrees with what the app shows.
    func refreshReminder(for plant: UserPlant) {
        let id = plant.id
        reminderVersions[id, default: 0] += 1
        let version = reminderVersions[id]

        guard plant.reminderEnabled else {
            enqueueReminder(nil, for: id)
            return
        }

        let request = WateringReminderRequest(
            plantID: id,
            plantName: plant.nickname,
            dueDate: recommendation(for: plant).dueDate,
            hour: plant.reminderHour
        )

        authorizationTasks[id] = Task { [weak self, notifications] in
            do {
                guard try await notifications.requestAuthorization() else { return }
                guard let self, self.reminderVersions[id] == version else { return }
                self.enqueueReminder(request, for: id)
            } catch {
                // A declined or unavailable notification must never block saved care.
            }
        }
    }

    /// Scheduling itself can suspend too. Cancellation must run after an in-flight add.
    private func enqueueReminder(_ request: WateringReminderRequest?, for id: UUID) {
        let previous = reminderOperations[id]
        reminderOperations[id] = Task { [notifications] in
            await previous?.value
            if let request {
                try? await notifications.scheduleWateringReminder(request)
            } else {
                await notifications.cancelWateringReminder(for: id)
            }
        }
    }

    /// Used by tests to await side effects already enqueued, without timing sleeps.
    func waitForReminderOperations(for id: UUID) async {
        await authorizationTasks[id]?.value
        await reminderOperations[id]?.value
    }

    private func save() -> Bool {
        guard context.hasChanges else { lastError = nil; return true }
        // Register relationship and property edits before a synchronous save attempt;
        // otherwise rollback can miss changes still awaiting the next run-loop turn.
        context.processPendingChanges()
        do {
            try persist(context)
            lastError = nil
            return true
        } catch {
            context.rollback()
            lastError = "That change could not be saved. \(error.localizedDescription)"
            return false
        }
    }
}

/// Value-only form state: dismissing an edit sheet cannot mutate or autosave a live model.
struct PlantEdits {
    var nickname: String
    var locationName: String
    var environment: PlantEnvironment
    var light: LightLevel
    var reminderEnabled: Bool
    var reminderHour: Int
    var notes: String

    @MainActor init(plant: UserPlant) {
        nickname = plant.nickname
        locationName = plant.locationName
        environment = plant.environment
        light = plant.light
        reminderEnabled = plant.reminderEnabled
        reminderHour = plant.reminderHour
        notes = plant.notes
    }

    @MainActor func apply(to plant: UserPlant) {
        plant.nickname = nickname
        plant.locationName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.environment = environment
        plant.light = light
        plant.reminderEnabled = reminderEnabled
        plant.reminderHour = reminderHour
        plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
