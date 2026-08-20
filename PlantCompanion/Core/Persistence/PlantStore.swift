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

    init(
        context: ModelContext,
        planner: WateringPlanner = WateringPlanner(),
        notifications: any NotificationScheduling
    ) {
        self.context = context
        self.planner = planner
        self.notifications = notifications
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
    ) -> UserPlant {
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
        save()
        refreshReminder(for: plant)
        return plant
    }

    func logWatering(
        for plant: UserPlant,
        amount: Double? = nil,
        unit: WaterUnit? = nil,
        timestamp: Date = .now,
        note: String = ""
    ) {
        let event = CareEvent(
            kind: .watered,
            timestamp: timestamp,
            amount: amount,
            waterUnit: unit,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(event)
        plant.careEvents.append(event)
        save()
        // The schedule is anchored to the newest watering, so the reminder moves with it.
        refreshReminder(for: plant)
    }

    /// Persists edits made directly to a `@Bindable` plant and re-times its reminder.
    func commitEdits(to plant: UserPlant) {
        plant.nickname = plant.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if plant.nickname.isEmpty { plant.nickname = plant.commonName }
        save()
        refreshReminder(for: plant)
    }

    func delete(_ plant: UserPlant) {
        let id = plant.id
        context.delete(plant)
        save()
        Task { [notifications] in await notifications.cancelWateringReminder(for: id) }
    }

    // MARK: - Reminders

    /// Reminders are always derived from the current recommendation, never scheduled ad hoc, so
    /// a plant can never hold a notification that disagrees with what the app shows.
    func refreshReminder(for plant: UserPlant) {
        let id = plant.id

        guard plant.reminderEnabled else {
            Task { [notifications] in await notifications.cancelWateringReminder(for: id) }
            return
        }

        let request = WateringReminderRequest(
            plantID: id,
            plantName: plant.nickname,
            dueDate: recommendation(for: plant).dueDate,
            hour: plant.reminderHour
        )

        Task { [notifications] in
            do {
                guard try await notifications.requestAuthorization() else { return }
                try await notifications.scheduleWateringReminder(request)
            } catch {
                // A declined or unavailable notification must never block saved care.
            }
        }
    }

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            lastError = nil
        } catch {
            lastError = "That change could not be saved. \(error.localizedDescription)"
        }
    }
}
