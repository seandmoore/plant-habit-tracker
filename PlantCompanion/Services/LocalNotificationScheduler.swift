import Foundation
import UserNotifications

actor LocalNotificationScheduler: NotificationScheduling {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleWateringReminder(_ request: WateringReminderRequest) async throws {
        let center = UNUserNotificationCenter.current()
        let identifier = identifier(for: request.plantID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Check \(request.plantName)’s soil"
        content.body = "Your care plan suggests a soil check today. Water only if the plant needs it."
        content.sound = .default

        let calendar = Calendar.autoupdatingCurrent
        var targetDate = calendar.date(bySettingHour: request.hour, minute: 0, second: 0, of: request.dueDate) ?? request.dueDate
        if targetDate <= .now {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
            targetDate = calendar.date(bySettingHour: request.hour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func cancelWateringReminder(for plantID: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: plantID)])
    }

    private func identifier(for id: UUID) -> String { "watering-\(id.uuidString)" }
}
