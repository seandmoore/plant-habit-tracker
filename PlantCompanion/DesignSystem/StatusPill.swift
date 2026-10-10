import SwiftUI

struct StatusPill: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let recommendation: CareRecommendation

    var body: some View {
        Label(recommendation.title, systemImage: symbolName)
            .font(.caption.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentTransition(.opacity)
            .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: recommendation.title)
    }

    private var color: Color {
        switch recommendation.status {
        case .overdue: PlantTheme.warning
        case .dueToday: PlantTheme.accent
        case .upcoming: .secondary
        }
    }

    private var symbolName: String {
        switch recommendation.status {
        case .overdue: "drop.circle.fill"
        case .dueToday: "drop.fill"
        case .upcoming: "calendar"
        }
    }
}
