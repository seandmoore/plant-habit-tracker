import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum PlantTheme {
    static let accent = adaptive(light: (0.16, 0.40, 0.29), dark: (0.55, 0.81, 0.64))
    static let moss = adaptive(light: (0.23, 0.36, 0.26), dark: (0.66, 0.83, 0.67))
    static let mint = adaptive(light: (0.85, 0.93, 0.87), dark: (0.16, 0.27, 0.21))
    static let warm = adaptive(light: (0.98, 0.97, 0.94), dark: (0.13, 0.15, 0.13))
    static let warning = adaptive(light: (0.62, 0.32, 0.12), dark: (0.96, 0.69, 0.42))

    static let cornerRadius: CGFloat = 24
    /// Keeps scrolling content clear of the floating companion ring.
    static let floatingClearance: CGFloat = 80
    /// Caps line length on iPad and Mac so text stays readable in a wide window.
    static let readableWidth: CGFloat = 760

    static let pageGradient = LinearGradient(
        colors: [accent.opacity(0.06), mint.opacity(0.12), .clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Brand colors follow the platform appearance just like semantic system colors.
    private static func adaptive(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        #if os(iOS)
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: 1)
        })
        #elseif os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: value.0, green: value.1, blue: value.2, alpha: 1)
        })
        #else
        Color(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

struct PlantPageBackground: View {
    var body: some View {
        PlantTheme.pageGradient
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// A quiet, semantic content surface; system glass is reserved for floating controls.
struct PlantSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    private let title: String?
    private let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: PlantTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PlantTheme.cornerRadius, style: .continuous)
                .strokeBorder(.primary.opacity(contrast == .increased ? 0.25 : 0.07), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.10 : 0.025), radius: 12, y: 4)
    }
}

extension View {
    func plantPage() -> some View {
        background { PlantPageBackground() }
            .tint(PlantTheme.accent)
    }

    /// The shared scrolling column: readable width, centred, clear of the companion ring.
    func plantReadableColumn() -> some View {
        padding()
            .padding(.bottom, PlantTheme.floatingClearance)
            .frame(maxWidth: PlantTheme.readableWidth)
            .frame(maxWidth: .infinity)
    }
}

/// Draws a divider between rows but never above the first one.
struct RowDivider: View {
    let isFirst: Bool

    var body: some View {
        if !isFirst { Divider() }
    }
}
