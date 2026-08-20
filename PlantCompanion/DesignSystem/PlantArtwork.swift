import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PlantArtwork: View {
    let imageData: Data?
    var size: CGFloat = 74
    var symbolName: String = "leaf.fill"

    var body: some View {
        Group {
            if let image = PlatformImageLoader.image(from: imageData) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(PlantTheme.mint.gradient)
            Image(systemName: symbolName)
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(PlantTheme.moss)
        }
    }
}

/// Bridges the two platform image types behind one call, so no view needs its own `#if os`.
enum PlatformImageLoader {
    static func image(from data: Data?) -> Image? {
        guard let data else { return nil }
        #if os(iOS)
        guard let platformImage = UIImage(data: data) else { return nil }
        return Image(uiImage: platformImage)
        #elseif os(macOS)
        guard let platformImage = NSImage(data: data) else { return nil }
        return Image(nsImage: platformImage)
        #else
        return nil
        #endif
    }
}

/// Re-encodes picked photos as JPEG so what the app stores and what it would upload are the
/// same bounded format, whatever the library handed over.
enum ImageDataNormalizer {
    static let compressionQuality = 0.82

    static func jpegData(from data: Data) -> Data? {
        #if os(iOS)
        return UIImage(data: data)?.jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        guard let representation = NSBitmapImageRep(data: data) else { return nil }
        return representation.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #else
        return nil
        #endif
    }

    /// Falls back to the original bytes when re-encoding is not possible.
    static func normalized(_ data: Data) -> Data {
        jpegData(from: data) ?? data
    }
}
