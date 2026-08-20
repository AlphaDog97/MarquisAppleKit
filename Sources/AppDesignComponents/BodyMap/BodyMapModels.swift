import SwiftUI

public enum BodyMapModel: Sendable {
    case male
    case female
}

public struct BodyMapRegionID: Hashable, RawRepresentable, Sendable {
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
    public let revealFactor: Double

    public init(
        id: BodyMapRegionID,
        color: Color,
        fillOpacity: Double = 1,
        glow: BodyMapGlowStyle = .init(),
        shadow: BodyMapShadowStyle = .init(),
        isSelected: Bool = false,
        revealFactor: Double = 1
    ) {
        self.id = id
        self.color = color
        self.fillOpacity = fillOpacity
        self.glow = glow
        self.shadow = shadow
        self.isSelected = isSelected
        self.revealFactor = revealFactor
    }
}

public struct BodyMapGlowStyle {
    public let color: Color
    public let opacity: Double
    public let radius: CGFloat
    public let energy: Double
    public let falloff: Double

    public init(
        color: Color = .clear,
        opacity: Double = 0,
        radius: CGFloat = 0,
        energy: Double = 0,
        falloff: Double = 1
    ) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.energy = energy
        self.falloff = falloff
    }
}

public struct BodyMapShadowStyle {
    public let color: Color
    public let opacity: Double
    public let radius: CGFloat
    public let energy: Double

    public init(
        color: Color = .black,
        opacity: Double = 0,
        radius: CGFloat = 0,
        energy: Double = 0
    ) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.energy = energy
    }
}

public struct BodyMapAnimationConfiguration {
    public let enabled: Bool
    public let revealDuration: Double
    public let transitionDuration: Double
    public let selectionDuration: Double
    public let regionDelay: Double
    public let intensityDurationScaling: Double

    public init(
        enabled: Bool = true,
        revealDuration: Double = 0.6,
        transitionDuration: Double = 0.3,
        selectionDuration: Double = 0.2,
        regionDelay: Double = 0.05,
        intensityDurationScaling: Double = 1
    ) {
        self.enabled = enabled
        self.revealDuration = revealDuration
        self.transitionDuration = transitionDuration
        self.selectionDuration = selectionDuration
        self.regionDelay = regionDelay
        self.intensityDurationScaling = intensityDurationScaling
    }
}
