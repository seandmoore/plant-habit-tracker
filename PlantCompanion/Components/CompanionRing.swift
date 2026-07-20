import SwiftUI

struct CompanionRing: View {
    let state: AppModel.CompanionState
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(angularGradient, lineWidth: 5)
                    .rotationEffect(state == .thinking ? .degrees(pulse ? 360 : 0) : .zero)
                Circle()
                    .fill(PlantTheme.mint.opacity(0.34))
                    .padding(7)
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PlantTheme.moss)
                    .symbolEffect(.pulse, options: .repeating, isActive: state == .speaking && !reduceMotion)
            }
            .frame(width: 58, height: 58)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .shadow(color: PlantTheme.moss.opacity(0.18), radius: 12, y: 5)
        .accessibilityLabel("Plant companion")
        .accessibilityHint("Opens care help and plant questions")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }

    private var symbol: String {
        switch state {
        case .idle: "leaf.fill"
        case .thinking: "ellipsis"
        case .speaking: "sparkles"
        }
    }

    private var angularGradient: AngularGradient {
        AngularGradient(colors: [PlantTheme.accent, PlantTheme.mint, .teal, PlantTheme.accent], center: .center)
    }
}
