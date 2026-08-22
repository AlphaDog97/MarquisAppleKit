import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum BodyMapBaseAppearance {
    static var inactiveColor: Color {
#if canImport(UIKit)
        Color(uiColor: .secondaryLabel)
#elseif canImport(AppKit)
        Color(nsColor: .secondaryLabelColor)
#else
        Color.secondary
#endif
    }

    static let baseOpacity: Double = 1
    static let backgroundColor = Color.clear
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
