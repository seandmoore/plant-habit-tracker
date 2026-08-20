import Foundation
import UserNotifications

/// Schedules the one reminder each plant may hold, replacing any earlier one so a plant can
/// never accumulate stale notifications.
actor LocalNotificationScheduler: NotificationScheduling {
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleWateringReminder(_ request: WateringReminderRequest) async throws {
        let center = UNUserNotificationCenter.current()
        let identifier = Self.identifier(for: request.plantID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Check \(request.plantName)’s soil"
        content.body = "Your care plan suggests a soil check today. Water only if the plant needs it."
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate(for: request)
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func cancelWateringReminder(for plantID: UUID) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: plantID)])
    }

    /// A due date already in the past would never fire, so an overdue plant is nudged tomorrow
    /// morning instead of silently dropping its reminder.
    func fireDate(for request: WateringReminderRequest, now: Date = .now) -> Date {
        let preferred = calendar.date(
            bySettingHour: request.hour,
            minute: 0,
            second: 0,
            of: request.dueDate
        ) ?? request.dueDate

        guard preferred <= now else { return preferred }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return calendar.date(bySettingHour: request.hour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    static func identifier(for plantID: UUID) -> String { "watering-\(plantID.uuidString)" }
}
