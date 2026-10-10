import SwiftUI

/// A consistent decorative SF Symbol tile; its adjacent label carries accessibility meaning.
struct PlantIcon: View {
    let symbolName: String
    var color: Color = PlantTheme.accent
    var size: CGFloat = 40

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.43, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(contrast == .increased ? 0.18 : 0.09), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}
