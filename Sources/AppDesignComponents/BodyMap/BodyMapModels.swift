import SwiftUI

public struct BodyMapRegionID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct BodyMapRegionStyle: Identifiable {
    public let id: BodyMapRegionID
    public let color: Color
    public let fillOpacity: Double
    public let glow: BodyMapGlowStyle
    public let shadow: BodyMapShadowStyle
    public let isSelected: Bool
    public let animationFactor: Double

    public init(
        id: BodyMapRegionID,
        color: Color,
        fillOpacity: Double = 1,
        glow: BodyMapGlowStyle = .init(),
        shadow: BodyMapShadowStyle = .init(),
        isSelected: Bool = false,
        animationFactor: Double = 1
    ) {
        self.id = id
        self.color = color
        self.fillOpacity = fillOpacity
        self.glow = glow
        self.shadow = shadow
        self.isSelected = isSelected
        self.animationFactor = animationFactor
    }
}

public struct BodyMapGlowStyle {
    public let opacity: Double
    public let radius: CGFloat

    public init(opacity: Double = 0, radius: CGFloat = 0) {
        self.opacity = opacity
        self.radius = radius
    }
}

public struct BodyMapShadowStyle {
    public let opacity: Double
    public let radius: CGFloat

    public init(opacity: Double = 0, radius: CGFloat = 0) {
        self.opacity = opacity
        self.radius = radius
    }
}

public struct BodyMapAnimationConfiguration {
    public let enabled: Bool
    public let revealDuration: Double
    public let transitionDuration: Double

    public init(
        enabled: Bool = true,
        revealDuration: Double = 0.6,
        transitionDuration: Double = 0.3
    ) {
        self.enabled = enabled
        self.revealDuration = revealDuration
        self.transitionDuration = transitionDuration
    }
}
