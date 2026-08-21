import SwiftUI

public struct BodyMapAppearance {
    public let inactiveColor: Color
    public let backgroundColor: Color
    public let glowEnabled: Bool
    public let regionStyles: [BodyMapRegionStyle]

    public init(
        inactiveColor: Color = .secondary,
        backgroundColor: Color = .clear,
        glowEnabled: Bool = true,
        regionStyles: [BodyMapRegionStyle] = []
    ) {
        self.inactiveColor = inactiveColor
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
            backgroundColor: backgroundColor,
            glowEnabled: glowEnabled,
            regionStyles: regions
        )
    }
}
