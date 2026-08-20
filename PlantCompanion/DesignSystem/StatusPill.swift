import SwiftUI

struct StatusPill: View {
    let recommendation: CareRecommendation

    var body: some View {
        Label(recommendation.title, systemImage: symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch recommendation.status {
        case .overdue: PlantTheme.warning
        case .dueToday: PlantTheme.accent
        case .upcoming: .secondary
        }
    }

    private var symbolName: String {
        recommendation.status == .upcoming ? "calendar" : "drop.fill"
    }
}
