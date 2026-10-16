import Foundation
import XCTest
@testable import PlantCompanion

final class OverdueReminderRegressionTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testOverdueReminderUsesTodayBeforeThePreferredHour() async throws {
        let scheduler = LocalNotificationScheduler(calendar: calendar)
        let reminder = request(dueDate: try date(10, 10))

        let fireDate = await scheduler.fireDate(for: reminder, now: try date(10, 16, 7))

        XCTAssertEqual(fireDate, try date(10, 16, 9))
    }

    func testRepeatedRelaunchesBeforeTheReminderDoNotPostponeIt() async throws {
        let reminder = request(dueDate: try date(10, 10))
        let launchTimes = [
            try date(10, 15, 12),
            try date(10, 15, 20),
            try date(10, 16, 7),
            try date(10, 16, 8, minute: 59, second: 59)
        ]

        for launchTime in launchTimes {
            let scheduler = LocalNotificationScheduler(calendar: calendar)
            let fireDate = await scheduler.fireDate(for: reminder, now: launchTime)

            XCTAssertEqual(fireDate, try date(10, 16, 9), "Relaunch at \(launchTime)")
            XCTAssertGreaterThan(fireDate, launchTime)
        }
    }

    func testOverdueReminderMovesToTomorrowAtOrAfterThePreferredHour() async throws {
        let scheduler = LocalNotificationScheduler(calendar: calendar)
        let reminder = request(dueDate: try date(10, 10))

        for now in [try date(10, 16, 9), try date(10, 16, 12)] {
            let fireDate = await scheduler.fireDate(for: reminder, now: now)

            XCTAssertEqual(fireDate, try date(10, 17, 9))
        }
    }

    func testYearBoundaryRelaunchKeepsTheUpcomingReminder() async throws {
        let scheduler = LocalNotificationScheduler(calendar: calendar)
        let reminder = request(dueDate: try date(12, 20))
        let beforeNewYear = await scheduler.fireDate(for: reminder, now: try date(12, 31, 12))
        let afterNewYear = await scheduler.fireDate(for: reminder, now: try date(1, 1, 7, year: 2027))

        XCTAssertEqual(beforeNewYear, try date(1, 1, 9, year: 2027))
        XCTAssertEqual(afterNewYear, beforeNewYear)
    }

    func testDaylightSavingChangesPreserveTheLocalReminderHour() async throws {
        var localCalendar = calendar
        localCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let scheduler = LocalNotificationScheduler(calendar: localCalendar)
        let cases = [(3, 7, 3, 8, 23), (10, 31, 11, 1, 25)]

        for (month, day, nextMonth, nextDay, elapsedHours) in cases {
            let yesterday = try date(month, day, 9, calendar: localCalendar)
            let reminder = request(dueDate: yesterday)
            let expected = try date(nextMonth, nextDay, 9, calendar: localCalendar)
            let firstFireDate = await scheduler.fireDate(
                for: reminder, now: try date(month, day, 12, calendar: localCalendar)
            )
            let restoredFireDate = await scheduler.fireDate(
                for: reminder, now: try date(nextMonth, nextDay, 7, calendar: localCalendar)
            )

            XCTAssertEqual(firstFireDate, expected)
            XCTAssertEqual(restoredFireDate, expected)
            XCTAssertEqual(firstFireDate.timeIntervalSince(yesterday), Double(elapsedHours * 3_600))
        }
    }

    private func request(dueDate: Date) -> WateringReminderRequest {
        WateringReminderRequest(plantID: UUID(), plantName: "Test plant", dueDate: dueDate, hour: 9)
    }

    private func date(
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        year: Int = 2026,
        calendar: Calendar? = nil
    ) throws -> Date {
        try XCTUnwrap((calendar ?? self.calendar).date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        )))
    }
}
