import SwiftUI

enum PlantTheme {
    static let accent = Color(red: 0.18, green: 0.48, blue: 0.31)
    static let moss = Color(red: 0.25, green: 0.38, blue: 0.23)
    static let mint = Color(red: 0.74, green: 0.88, blue: 0.76)
    static let warm = Color(red: 0.96, green: 0.94, blue: 0.87)
    static let warning = Color(red: 0.76, green: 0.39, blue: 0.18)

    static let cornerRadius: CGFloat = 24
    /// Keeps scrolling content clear of the floating companion ring.
    static let floatingClearance: CGFloat = 80
    /// Caps line length on iPad and Mac so text stays readable in a wide window.
    static let readableWidth: CGFloat = 760

    static let pageGradient = LinearGradient(
        colors: [warm.opacity(0.78), mint.opacity(0.38)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PlantPageBackground: View {
    var body: some View {
        PlantTheme.pageGradient
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// The app's one content container.
struct PlantSection<Content: View>: View {
    private let title: String?
    private let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(.title3.weight(.semibold))
            }
            content
        }
        .padding(18)
        .background(.background.opacity(0.9), in: RoundedRectangle(cornerRadius: PlantTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PlantTheme.cornerRadius, style: .continuous)
                .stroke(.primary.opacity(0.07), lineWidth: 1)
        }
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
