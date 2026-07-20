import SwiftUI

struct OnboardingView: View {
    let completion: () -> Void
    @State private var step = 0

    var body: some View {
        ZStack {
            PlantPageBackground()
            VStack(spacing: 28) {
                Spacer()
                CompanionRing(state: step == 2 ? .speaking : .idle) {}
                    .scaleEffect(1.45)
                    .allowsHitTesting(false)

                Group {
                    switch step {
                    case 0:
                        OnboardingPage(
                            symbol: "leaf.fill",
                            title: "Meet your calm care companion",
                            message: "Keep indoor and outdoor plants together, with readable guidance grounded in what you record."
                        )
                    case 1:
                        OnboardingPage(
                            symbol: "drop.degreesign.fill",
                            title: "Observe, then water",
                            message: "Care dates remind you to check the soil. Quick logs reveal patterns without turning plant care into a streak."
                        )
                    default:
                        OnboardingPage(
                            symbol: "viewfinder",
                            title: "Search, scan, and ask",
                            message: "Explore a starter catalog, get photo suggestions, and ask the companion to explain saved care information."
                        )
                    }
                }
                .id(step)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == step ? PlantTheme.accent : .secondary.opacity(0.25))
                            .frame(width: index == step ? 28 : 8, height: 8)
                    }
                }
                .accessibilityLabel("Step \(step + 1) of 3")

                Button(step == 2 ? "Add my first plant" : "Continue") {
                    if step == 2 {
                        completion()
                    } else {
                        withAnimation(.snappy) { step += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if step > 0 {
                    Button("Back") {
                        withAnimation(.snappy) { step -= 1 }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(28)
            .frame(maxWidth: 620)
        }
        .tint(PlantTheme.accent)
    }
}

private struct OnboardingPage: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.largeTitle.bold())
                .labelStyle(.titleOnly)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .accessibilityElement(children: .combine)
    }
}
