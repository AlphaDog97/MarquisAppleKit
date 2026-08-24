import CoreGraphics

enum BodyMapGlowMetrics {
    /// Keeps the halo close to the highlighted anatomy so it reads as a subtle
    /// edge glow instead of a large illuminated region.
    static let spreadScale: CGFloat = 0.4

    /// Softens the halo globally while preserving each region's relative glow
    /// intensity and animation.
    static let opacityScale: Double = 0.55

    /// Keeps a restrained amount of glow inside the highlighted anatomy after
    /// the fill is drawn, so the region still feels illuminated without looking
    /// like a solid neon layer.
    static let innerOpacityScale: Double = 0.18
}
