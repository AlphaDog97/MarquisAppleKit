#if canImport(UIKit)
import Foundation
import UIKit

/// App identity displayed at the top of a share preview card.
public struct AppSharePreviewBrand {
    public let name: String
    public let icon: UIImage?

    public init(name: String, icon: UIImage? = nil) {
        self.name = name
        self.icon = icon
    }

    /// Resolves the current app's display name and primary icon from its bundle.
    public static func current(
        bundle: Bundle = .main,
        fallbackName: String = "App",
        fallbackIconName: String? = "ShareAppIcon"
    ) -> AppSharePreviewBrand {
        AppSharePreviewBrand(
            name: resolvedName(in: bundle, fallbackName: fallbackName),
            icon: resolvedIcon(in: bundle, fallbackIconName: fallbackIconName)
        )
    }

    private static func resolvedName(in bundle: Bundle, fallbackName: String) -> String {
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String

        return [displayName, bundleName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? fallbackName
    }

    private static func resolvedIcon(
        in bundle: Bundle,
        fallbackIconName: String?
    ) -> UIImage? {
        guard
            let icons = bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            !iconFiles.isEmpty
        else {
            return fallbackIconName.flatMap { UIImage(named: $0, in: bundle, compatibleWith: nil) }
        }

        if let namedImage = iconFiles.reversed().compactMap({
            UIImage(named: $0, in: bundle, compatibleWith: nil)
        }).first {
            return namedImage
        }

        guard let pngURLs = bundle.urls(forResourcesWithExtension: "png", subdirectory: nil) else {
            return fallbackIconName.flatMap { UIImage(named: $0, in: bundle, compatibleWith: nil) }
        }

        for baseName in iconFiles.reversed() {
            let candidates = pngURLs.filter {
                $0.deletingPathExtension().lastPathComponent.hasPrefix(baseName)
            }
            let bestImage = candidates
                .compactMap { UIImage(contentsOfFile: $0.path) }
                .max { imagePixelCount($0) < imagePixelCount($1) }

            if let bestImage {
                return bestImage
            }
        }

        return fallbackIconName.flatMap { UIImage(named: $0, in: bundle, compatibleWith: nil) }
    }

    private static func imagePixelCount(_ image: UIImage) -> CGFloat {
        image.size.width * image.size.height * image.scale * image.scale
    }
}
#endif
