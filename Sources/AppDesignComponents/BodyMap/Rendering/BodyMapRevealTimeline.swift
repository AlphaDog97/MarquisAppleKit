import Foundation

struct BodyMapRevealRequest: Equatable {
    let id: UUID
    let regionIntensities: [BodyMapRegionID: Double]
}

struct BodyMapRevealProgress {
    let fill: Float
    let glow: Float
    let shadow: Float
    let selection: Float

    static let complete = BodyMapRevealProgress(
        fill: 1,
        glow: 1,
        shadow: 1,
        selection: 1
    )
}

enum BodyMapRevealTimeline {
    static let totalDuration: TimeInterval = 0.58
    static let presentationDelay: TimeInterval = 0.04

    private static let maximumStartDelay: TimeInterval = 0.10
    private static let fillDuration: TimeInterval = 0.28
    private static let glowDelay: TimeInterval = 0.035
    private static let glowDuration: TimeInterval = 0.34
    private static let shadowDelay: TimeInterval = 0.02
    private static let shadowDuration: TimeInterval = 0.30
    private static let glowOvershoot: Float = 1.08
    private static let glowOvershootStart: Float = 0.76

    static func progress(
        for region: BodyMapRegionID,
        request: BodyMapRevealRequest,
        elapsed: TimeInterval
    ) -> BodyMapRevealProgress {
        guard let rawIntensity = request.regionIntensities[region] else {
            return .complete
        }

        let intensity = min(max(rawIntensity, 0), 1)
        let startDelay = presentationDelay
            + maximumStartDelay * (1 - intensity)
        let fill = smootherProgress(
            normalizedProgress(
                elapsed: elapsed,
                start: startDelay,
                duration: fillDuration
            )
        )
        let glow = glowProgress(
            normalizedProgress(
                elapsed: elapsed,
                start: startDelay + glowDelay,
                duration: glowDuration
            )
        )
        let shadow = smootherProgress(
            normalizedProgress(
                elapsed: elapsed,
                start: startDelay + shadowDelay,
                duration: shadowDuration
            )
        )

        return BodyMapRevealProgress(
            fill: fill,
            glow: glow,
            shadow: shadow,
            selection: fill
        )
    }

    private static func normalizedProgress(
        elapsed: TimeInterval,
        start: TimeInterval,
        duration: TimeInterval
    ) -> Float {
        guard duration > 0 else { return 1 }
        return Float(min(max((elapsed - start) / duration, 0), 1))
    }

    private static func smootherProgress(_ progress: Float) -> Float {
        let value = min(max(progress, 0), 1)
        return value * value * value
            * (value * (value * 6 - 15) + 10)
    }

    private static func glowProgress(_ progress: Float) -> Float {
        guard progress < 1 else { return 1 }
        guard progress > 0 else { return 0 }

        if progress < glowOvershootStart {
            let rise = smootherProgress(progress / glowOvershootStart)
            return rise * glowOvershoot
        }

        let settle = smootherProgress(
            (progress - glowOvershootStart) / (1 - glowOvershootStart)
        )
        return glowOvershoot + ((1 - glowOvershoot) * settle)
    }
}
