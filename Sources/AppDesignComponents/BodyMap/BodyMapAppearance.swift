import SwiftUI

public struct BodyMapAppearance {
    public let inactiveColor: Color
    public let backgroundColor: Color
    public let regionStyles: [BodyMapRegionStyle]

    public init(
        inactiveColor: Color = .secondary,
        backgroundColor: Color = .clear,
        regionStyles: [BodyMapRegionStyle] = []
    ) {
        self.inactiveColor = inactiveColor
        self.backgroundColor = backgroundColor
        self.regionStyles = regionStyles
    }

    public func style(for region: BodyMapRegionID) -> BodyMapRegionStyle? {
        regionStyles.first { $0.id == region }
    }

    func withRegions(_ regions: [BodyMapRegionStyle]) -> BodyMapAppearance {
        BodyMapAppearance(
            inactiveColor: inactiveColor,
            backgroundColor: backgroundColor,
            regionStyles: regions
        )
    }
}
