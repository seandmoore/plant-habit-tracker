import SwiftUI

struct OnboardingView: View {
    let completion: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0

    private struct Page: Identifiable {
        let id: Int
        let symbolName: String
        let eyebrow: String
        let title: String
        let message: String
    }

    private static let pages: [Page] = [
        Page(
            id: 0,
            symbolName: "leaf.fill",
            eyebrow: "A little care, every day",
            title: "Room to grow.",
            message: "A calm home for your plants. Keep their stories, find your rhythm, and learn as you grow."
        ),
        Page(
            id: 1,
            symbolName: "drop.degreesign.fill",
            eyebrow: "Follow your plant’s lead",
            title: "Observe. Then water.",
            message: "Gentle reminders invite you to check the soil. Log the care you give and discover patterns, without chasing a streak."
        ),
        Page(
            id: 2,
            symbolName: "camera.macro",
            eyebrow: "Stay curious",
            title: "Get to know your green.",
            message: "Explore plants, compare photo suggestions, and ask a companion that draws on your saved care details."
        )
    ]

    private var isLastStep: Bool { step == Self.pages.count - 1 }
    private var page: Page { Self.pages[step] }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Label("Plant Companion", systemImage: "leaf")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PlantTheme.accent)
                    .padding(.top, 24)

                illustration

                VStack(spacing: 12) {
                    Text(page.eyebrow)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PlantTheme.accent)
                    Text(page.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(page.message)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(page.id)
                .transition(PlantMotion.transition(reduceMotion: reduceMotion))
                .accessibilityElement(children: .combine)

                stepIndicator

                VStack(spacing: 14) {
                    Button(action: advance) {
                        Label(isLastStep ? "Start my collection" : "Continue", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)

                    Button("Back", systemImage: "arrow.left") {
                        withAnimation(PlantMotion.animation(reduceMotion: reduceMotion)) { step -= 1 }
                    }
                    .buttonStyle(.borderless)
                    .disabled(step == 0)
                    .opacity(step == 0 ? 0 : 1)
                    .accessibilityHidden(step == 0)
                }
                .frame(maxWidth: 320)
            }
            .padding(28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .plantPage()
        .defaultScrollAnchor(.center, for: .alignment)
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(PlantTheme.accent.opacity(0.04))
                .frame(width: 224, height: 224)
            Circle()
                .strokeBorder(PlantTheme.accent.opacity(0.12), lineWidth: 1)
                .frame(width: 192, height: 192)
            PlantArtwork(imageData: nil, size: 144, symbolName: page.symbolName)
                .id(page.id)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.92)))
        }
        .accessibilityHidden(true)
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Self.pages) { item in
                Capsule()
                    .fill(item.id == step ? PlantTheme.accent : .secondary.opacity(0.25))
                    .frame(width: item.id == step ? 26 : 7, height: 7)
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
        withAnimation(PlantMotion.animation(reduceMotion: reduceMotion)) { step += 1 }
    }
}
