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
                .help("Ask your plant companion")
        } else {
            ring.accessibilityHidden(true)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(angularGradient, lineWidth: 3)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
            Circle()
                .fill(PlantTheme.accent.opacity(0.08))
                .padding(7)
            Image(systemName: state.symbolName)
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(PlantTheme.accent)
                .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                .symbolEffect(.pulse, options: .repeating, isActive: state == .speaking && !reduceMotion)
        }
        .frame(width: 58, height: 58)
        .contentShape(Circle())
        .onChange(of: shouldSpin, initial: true) { _, spin in
            updateSpin(spin)
        }
        .onDisappear { updateSpin(false) }
    }

    private var shouldSpin: Bool { state == .thinking && !reduceMotion }

    private func updateSpin(_ spin: Bool) {
        guard spin else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { isSpinning = false }
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
