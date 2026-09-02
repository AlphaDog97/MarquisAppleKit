import CoreGraphics
import Foundation

enum BodyMapMorphologyWarp {
    static func sourceNormalizedPoint(
        _ point: CGPoint,
        morphology: BodyMapMorphology
    ) -> CGPoint {
        guard !morphology.isNeutral else { return point }

        let x = Double(point.x)
        let y = Double(point.y)
        let torsoScale = torsoEnvelopeScale(y: y, morphology: morphology)
        let armScale = armEnvelopeScale(y: y, morphology: morphology)
        let armInfluence = armInfluence(x: x, y: y)
        let scale = mix(torsoScale, armScale, armInfluence)

        return CGPoint(
            x: 0.5 + (x - 0.5) / scale,
            y: y
        )
    }

    private static func torsoEnvelopeScale(
        y: Double,
        morphology: BodyMapMorphology
    ) -> Double {
        if y <= 0.10 { return 1 }
        if y <= 0.20 {
            return smoothedMix(1, morphology.shoulders, y, 0.10, 0.20)
        }
        if y <= 0.29 {
            return smoothedMix(
                morphology.shoulders,
                morphology.chest,
                y,
                0.20,
                0.29
            )
        }
        if y <= 0.41 {
            return smoothedMix(
                morphology.chest,
                morphology.waist,
                y,
                0.29,
                0.41
            )
        }
        if y <= 0.52 {
            return smoothedMix(
                morphology.waist,
                morphology.hips,
                y,
                0.41,
                0.52
            )
        }
        if y <= 0.66 {
            return smoothedMix(
                morphology.hips,
                morphology.thighs,
                y,
                0.52,
                0.66
            )
        }
        if y <= 0.84 {
            return smoothedMix(
                morphology.thighs,
                morphology.calves,
                y,
                0.66,
                0.84
            )
        }
        if y <= 0.94 {
            return smoothedMix(morphology.calves, 1, y, 0.84, 0.94)
        }
        return 1
    }

    private static func armEnvelopeScale(
        y: Double,
        morphology: BodyMapMorphology
    ) -> Double {
        if y <= 0.18 { return 1 }
        if y <= 0.28 {
            return smoothedMix(1, morphology.upperArms, y, 0.18, 0.28)
        }
        if y <= 0.38 { return morphology.upperArms }
        if y <= 0.52 {
            return smoothedMix(
                morphology.upperArms,
                morphology.forearms,
                y,
                0.38,
                0.52
            )
        }
        if y <= 0.62 {
            return smoothedMix(morphology.forearms, 1, y, 0.52, 0.62)
        }
        return 1
    }

    private static func armInfluence(x: Double, y: Double) -> Double {
        let horizontal = smoothstep(0.19, 0.27, abs(x - 0.5))
        let verticalEntry = smoothstep(0.16, 0.23, y)
        let verticalExit = 1 - smoothstep(0.58, 0.66, y)
        return horizontal * verticalEntry * verticalExit
    }

    private static func smoothedMix(
        _ source: Double,
        _ target: Double,
        _ value: Double,
        _ lower: Double,
        _ upper: Double
    ) -> Double {
        mix(source, target, smoothstep(lower, upper, value))
    }

    private static func smoothstep(
        _ lower: Double,
        _ upper: Double,
        _ value: Double
    ) -> Double {
        guard upper > lower else { return value >= upper ? 1 : 0 }
        let t = min(max((value - lower) / (upper - lower), 0), 1)
        return t * t * (3 - 2 * t)
    }

    private static func mix(
        _ source: Double,
        _ target: Double,
        _ progress: Double
    ) -> Double {
        source + (target - source) * progress
    }
}
