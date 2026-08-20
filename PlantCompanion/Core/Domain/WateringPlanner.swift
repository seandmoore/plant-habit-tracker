import Foundation

/// Turns a `CareProfile` into a dated, explainable soil check.
///
/// A pure value type over a fixed calendar, so it can be exercised directly by the shared
/// contract vectors and used from any concurrency domain.
struct WateringPlanner: Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    /// The interval and the phrases explaining every modifier that moved it.
    struct AppliedInterval: Hashable, Sendable {
        let days: Int
        let factors: [String]
    }

    func interval(for profile: CareProfile, asOf date: Date) -> AppliedInterval {
        let month = calendar.component(.month, from: date)
        let modifiers: [(days: Int, factor: String?)] = [
            CareRules.environmentModifier(for: profile.environment).map { ($0.days, $0.factor) },
            CareRules.lightModifier(for: profile.light).map { ($0.days, $0.factor) },
            CareRules.seasonModifier(month: month, environment: profile.environment).map { ($0.days, $0.factor) }
        ].compactMap { $0 }

        var days = max(1, profile.baselineWateringDays)
        var factors: [String] = []

        for modifier in modifiers {
            days += modifier.days
            if let factor = modifier.factor { factors.append(factor) }
        }

        days = min(max(days, CareRules.minimumIntervalDays), CareRules.maximumIntervalDays)
        return AppliedInterval(days: days, factors: factors)
    }

    func plan(for profile: CareProfile, plantID: UUID, asOf date: Date = .now) -> CareRecommendation {
        let applied = interval(for: profile, asOf: date)
        let dueDate = calendar.date(byAdding: .day, value: applied.days, to: profile.anchor) ?? date
        let dayDifference = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: dueDate)
        ).day ?? 0

        return CareRecommendation(
            plantID: plantID,
            dueDate: dueDate,
            intervalDays: applied.days,
            status: status(forDayDifference: dayDifference),
            title: title(forDayDifference: dayDifference),
            reason: "\(CareRules.Phrasing.explanation(factors: applied.factors)) \(CareRules.Phrasing.reasonSuffix)"
        )
    }

    private func status(forDayDifference difference: Int) -> CareRecommendation.Status {
        if difference < 0 { return .overdue }
        if difference == 0 { return .dueToday }
        return .upcoming
    }

    private func title(forDayDifference difference: Int) -> String {
        if difference < 0 { return CareRules.Phrasing.overdueTitle }
        if difference == 0 { return CareRules.Phrasing.dueTodayTitle }
        return CareRules.Phrasing.upcomingTitle(days: difference)
    }
}
