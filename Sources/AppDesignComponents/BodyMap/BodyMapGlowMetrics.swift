import CoreGraphics

enum BodyMapGlowMetrics {
    /// Keeps the halo close to the highlighted anatomy so it reads as a subtle
    /// edge glow instead of a large illuminated region.
    static let spreadScale: CGFloat = 0.4

    /// Softens the halo globally while preserving each region's relative glow
    /// intensity and animation.
    static let opacityScale: Double = 0.55
}
