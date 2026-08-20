import SwiftUI

/// The companion's presence. Spins only while it is thinking, and never when Reduce Motion is on.
struct CompanionRing: View {
    var state: CompanionState = .idle
    /// Decorative placements pass no action and stay out of the tab order.
    var action: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    var body: some View {
        if let action {
            Button(action: action) { ring }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .shadow(color: PlantTheme.moss.opacity(0.18), radius: 12, y: 5)
                .accessibilityLabel("Plant companion")
                .accessibilityHint("Opens care help and plant questions")
        } else {
            ring.accessibilityHidden(true)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(angularGradient, lineWidth: 5)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
            Circle()
                .fill(PlantTheme.mint.opacity(0.34))
                .padding(7)
            Image(systemName: state.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PlantTheme.moss)
                .symbolEffect(.pulse, options: .repeating, isActive: state == .speaking && !reduceMotion)
        }
        .frame(width: 58, height: 58)
        .contentShape(Circle())
        .onChange(of: shouldSpin, initial: true) { _, spin in
            updateSpin(spin)
        }
    }

    private var shouldSpin: Bool { state == .thinking && !reduceMotion }

    private func updateSpin(_ spin: Bool) {
        guard spin else {
            withAnimation(.linear(duration: 0.2)) { isSpinning = false }
            return
        }
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            isSpinning = true
        }
    }

    private var angularGradient: AngularGradient {
        AngularGradient(colors: [PlantTheme.accent, PlantTheme.mint, .teal, PlantTheme.accent], center: .center)
    }
}
