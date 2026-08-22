import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct BodyMapAppearance {
    public let inactiveColor: Color
    public let baseOpacity: Double
    public let backgroundColor: Color
    public let glowEnabled: Bool
    public let regionStyles: [BodyMapRegionStyle]

    public static var adaptiveInactiveColor: Color {
#if canImport(UIKit)
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? .secondaryLabel
                    : .tertiaryLabel
            }
        )
#elseif canImport(AppKit)
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? .secondaryLabelColor
                    : .tertiaryLabelColor
            }
        )
#else
        Color.secondary
#endif
    }

    public init(
        baseOpacity: Double = 1,
        backgroundColor: Color = .clear,
        glowEnabled: Bool = true,
        regionStyles: [BodyMapRegionStyle] = []
    ) {
        self.init(
            inactiveColor: Self.adaptiveInactiveColor,
            baseOpacity: baseOpacity,
            backgroundColor: backgroundColor,
            glowEnabled: glowEnabled,
            regionStyles: regionStyles
        )
    }

    public init(
        inactiveColor: Color,
        baseOpacity: Double = 0.10,
        backgroundColor: Color = .clear,
        glowEnabled: Bool = true,
        regionStyles: [BodyMapRegionStyle] = []
    ) {
        self.inactiveColor = inactiveColor
        self.baseOpacity = baseOpacity
        self.backgroundColor = backgroundColor
        self.glowEnabled = glowEnabled
        self.regionStyles = regionStyles
    }

    public func style(for region: BodyMapRegionID) -> BodyMapRegionStyle? {
        regionStyles.first { $0.id == region }
    }

    func withRegions(_ regions: [BodyMapRegionStyle]) -> BodyMapAppearance {
        BodyMapAppearance(
            inactiveColor: inactiveColor,
            baseOpacity: baseOpacity,
            backgroundColor: backgroundColor,
            glowEnabled: glowEnabled,
            regionStyles: regions
        )
    }
}
