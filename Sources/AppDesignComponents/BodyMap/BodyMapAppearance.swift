import SwiftUI

enum BodyMapBaseAppearance {
    static let inactiveColor = Color.black.opacity(0.6)
    static let baseOpacity: Double = 1
    static let backgroundColor = Color.clear
    static let glowEnabled = true
}

public struct BodyMapAppearance {
    public let inactiveColor: Color
    public let inactiveRegionColor: Color
    public let baseOpacity: Double
    public let backgroundColor: Color
    public let glowEnabled: Bool
    public let regionStyles: [BodyMapRegionStyle]

    public init(regionStyles: [BodyMapRegionStyle] = []) {
        self.init(
            inactiveColor: BodyMapBaseAppearance.inactiveColor,
            regionStyles: regionStyles
        )
    }

    public init(
        inactiveColor: Color = .secondary,
        inactiveRegionColor: Color = Color(.tertiaryLabel),
        baseOpacity: Double = 0.10,
        backgroundColor: Color = .clear,
        glowEnabled: Bool = true,
        regionStyles: [BodyMapRegionStyle] = []
    ) {
        self.inactiveColor = inactiveColor
        self.inactiveRegionColor = inactiveRegionColor
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
            inactiveRegionColor: inactiveRegionColor,
            baseOpacity: baseOpacity,
            backgroundColor: backgroundColor,
            glowEnabled: glowEnabled,
            regionStyles: regions
        )
    }
}
