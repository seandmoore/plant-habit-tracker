import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PlantArtwork: View {
    let imageData: Data?
    var size: CGFloat = 74

    var body: some View {
        Group {
            #if os(iOS)
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
            #elseif os(macOS)
            if let imageData, let image = NSImage(data: imageData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
            #endif
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            PlantTheme.mint.gradient
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(PlantTheme.moss)
        }
    }
}

enum ImageDataNormalizer {
    static func jpegData(from data: Data) -> Data? {
        #if os(iOS)
        return UIImage(data: data)?.jpegData(compressionQuality: 0.82)
        #elseif os(macOS)
        guard let representation = NSBitmapImageRep(data: data) else { return nil }
        return representation.representation(using: .jpeg, properties: [.compressionFactor: 0.82])
        #endif
    }
}
