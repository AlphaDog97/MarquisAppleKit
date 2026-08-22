import SwiftUI

enum BodyMapBaseAppearance {
    static let inactiveColor = Color.primary.opacity(0.10)
    static let baseOpacity: Double = 1
    static let backgroundColor = Color.black.opacity(0.6)
    static let glowEnabled = true
}

public struct BodyMapAppearance {
    public let regionStyles: [BodyMapRegionStyle]

    public init(regionStyles: [BodyMapRegionStyle] = []) {
        self.regionStyles = regionStyles
    }

    public func style(for region: BodyMapRegionID) -> BodyMapRegionStyle? {
        regionStyles.first { $0.id == region }
    }

    func withRegions(_ regions: [BodyMapRegionStyle]) -> BodyMapAppearance {
        BodyMapAppearance(regionStyles: regions)
    }
}
