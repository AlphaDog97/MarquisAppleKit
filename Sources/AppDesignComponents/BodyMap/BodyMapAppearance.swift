import SwiftUI

enum BodyMapBaseAppearance {
    static let inactiveColor = Color.black.opacity(0.6)
    static let baseOpacity: Double = 1
    static let backgroundColor = Color.clear
    static let glowEnabled = true
}

public struct BodyMapAppearance {
    public let inactiveColor: Color
    public let regionStyles: [BodyMapRegionStyle]

    public init(regionStyles: [BodyMapRegionStyle] = []) {
        self.init(
            inactiveColor: BodyMapBaseAppearance.inactiveColor,
            regionStyles: regionStyles
        )
    }

    public init(
        inactiveColor: Color,
        regionStyles: [BodyMapRegionStyle] = []
    ) {
        self.inactiveColor = inactiveColor
        self.regionStyles = regionStyles
    }

    public func style(for region: BodyMapRegionID) -> BodyMapRegionStyle? {
        regionStyles.first { $0.id == region }
    }

    func withRegions(_ regions: [BodyMapRegionStyle]) -> BodyMapAppearance {
        BodyMapAppearance(
            inactiveColor: inactiveColor,
            regionStyles: regions
        )
    }
}
