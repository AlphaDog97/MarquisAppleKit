import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum BodyMapBaseAppearance {
    static var inactiveColor: Color {
#if canImport(UIKit)
        Color(uiColor: .tertiaryLabel)
#elseif canImport(AppKit)
        Color(nsColor: .tertiaryLabelColor)
#else
        Color.primary.opacity(0.30)
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
