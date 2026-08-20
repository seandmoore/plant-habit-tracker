import SwiftUI

struct OnboardingView: View {
    let completion: () -> Void

    @State private var step = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbolName: String
        let title: String
        let message: String
    }

    private static let pages: [Page] = [
        Page(
            symbolName: "leaf.fill",
            title: "Meet your calm care companion",
            message: "Keep indoor and outdoor plants together, with readable guidance grounded in what you record."
        ),
        Page(
            symbolName: "drop.degreesign.fill",
            title: "Observe, then water",
            message: "Care dates remind you to check the soil. Quick logs reveal patterns without turning plant care into a streak."
        ),
        Page(
            symbolName: "viewfinder",
            title: "Search, scan, and ask",
            message: "Explore a starter catalog, get photo suggestions, and ask the companion to explain saved care information."
        )
    ]

    private var isLastStep: Bool { step == Self.pages.count - 1 }
    private var page: Page { Self.pages[min(step, Self.pages.count - 1)] }

    var body: some View {
        ZStack {
            PlantPageBackground()

            VStack(spacing: 28) {
                Spacer()

                CompanionRing(state: isLastStep ? .speaking : .idle)
                    .scaleEffect(1.45)

                VStack(spacing: 14) {
                    Text(page.title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(page.message)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .id(page.id)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .accessibilityElement(children: .combine)

                stepIndicator

                Button(isLastStep ? "Add my first plant" : "Continue") { advance() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                if step > 0 {
                    Button("Back") { withAnimation(.snappy) { step -= 1 } }
                        .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(28)
            .frame(maxWidth: 620)
        }
        .tint(PlantTheme.accent)
    }

    private var stepIndicator: some View {
        HStack(spacing: 7) {
            ForEach(Array(Self.pages.enumerated()), id: \.element.id) { index, _ in
                Capsule()
                    .fill(index == step ? PlantTheme.accent : .secondary.opacity(0.25))
                    .frame(width: index == step ? 28 : 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of \(Self.pages.count)")
    }

    private func advance() {
        guard !isLastStep else {
            completion()
            return
        }
        withAnimation(.snappy) { step += 1 }
    }
}
