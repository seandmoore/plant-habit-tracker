import Foundation

struct DefaultRecommendationEngine: RecommendationEngine {
    var calendar: Calendar = .autoupdatingCurrent

    func wateringRecommendation(for plant: UserPlant, asOf date: Date = .now) -> CareRecommendation {
        var interval = max(1, plant.baselineWateringDays)
        var factors: [String] = []

        switch plant.environment {
        case .indoor:
            factors.append("kept indoors")
        case .outdoorContainer:
            interval -= 2
            factors.append("an outdoor pot can dry faster")
        case .outdoorGround:
            interval += 1
            factors.append("garden soil holds moisture longer than many pots")
        }

        switch plant.light {
        case .low:
            interval += 2
            factors.append("lower light usually slows water use")
        case .medium:
            break
        case .brightIndirect:
            interval -= 1
            factors.append("bright light can increase water use")
        case .direct:
            interval -= 2
            factors.append("direct sun can dry soil faster")
        }

        let month = calendar.component(.month, from: date)
        if plant.environment != .indoor && [6, 7, 8].contains(month) {
            interval -= 2
            factors.append("it is the warmer part of the year")
        } else if [11, 12, 1, 2].contains(month) {
            interval += 2
            factors.append("plants often use less water in cooler months")
        }

        interval = min(max(interval, 1), 45)
        let anchor = plant.lastWateredAt ?? plant.dateAdded
        let dueDate = calendar.date(byAdding: .day, value: interval, to: anchor) ?? date
        let startOfToday = calendar.startOfDay(for: date)
        let startOfDueDate = calendar.startOfDay(for: dueDate)
        let dayDifference = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0

        let status: CareRecommendation.Status
        let title: String
        if dayDifference < 0 {
            status = .overdue
            title = "Check soil now"
        } else if dayDifference == 0 {
            status = .dueToday
            title = "Check soil today"
        } else {
            status = .upcoming
            title = "Check soil in \(dayDifference) day\(dayDifference == 1 ? "" : "s")"
        }

        let explanation = factors.isEmpty
            ? "Based on this species’ starting care interval."
            : "Based on its starting interval and the fact that it is \(factors.joined(separator: ", "))."

        return CareRecommendation(
            plantID: plant.id,
            dueDate: dueDate,
            intervalDays: interval,
            status: status,
            title: title,
            reason: "\(explanation) Feel the soil before watering."
        )
    }
}
