import CoreGraphics

enum BodyMapGlowMetrics {
    /// Keeps the visible glow close to the highlighted anatomy instead of
    /// letting the blur spread too far beyond the region mask.
    static let spreadScale: CGFloat = 0.6
}
