import Foundation

public struct BodyMapMorphology: Equatable, Sendable {
    public static let supportedScaleRange: ClosedRange<Double> = 0.92...1.12
    public static let neutral = BodyMapMorphology()

    public let shoulders: Double
    public let chest: Double
    public let waist: Double
    public let hips: Double
    public let upperArms: Double
    public let forearms: Double
    public let thighs: Double
    public let calves: Double

    public init(
        shoulders: Double = 1,
        chest: Double = 1,
        waist: Double = 1,
        hips: Double = 1,
        upperArms: Double = 1,
        forearms: Double = 1,
        thighs: Double = 1,
        calves: Double = 1
    ) {
        let values = [
            shoulders,
            chest,
            waist,
            hips,
            upperArms,
            forearms,
            thighs,
            calves
        ]
        precondition(
            values.allSatisfy {
                $0.isFinite && Self.supportedScaleRange.contains($0)
            },
            "BodyMap morphology scales must be finite and within \(Self.supportedScaleRange)"
        )

        self.shoulders = shoulders
        self.chest = chest
        self.waist = waist
        self.hips = hips
        self.upperArms = upperArms
        self.forearms = forearms
        self.thighs = thighs
        self.calves = calves
    }

    public var isNeutral: Bool {
        self == .neutral
    }

    var torsoScales: SIMD4<Float> {
        SIMD4(
            Float(shoulders),
            Float(chest),
            Float(waist),
            Float(hips)
        )
    }

    var limbScales: SIMD4<Float> {
        SIMD4(
            Float(upperArms),
            Float(forearms),
            Float(thighs),
            Float(calves)
        )
    }

    func interpolated(from source: Self, progress: Float) -> Self {
        let progress = Double(min(max(progress, 0), 1))
        return Self(
            shoulders: mix(source.shoulders, shoulders, progress),
            chest: mix(source.chest, chest, progress),
            waist: mix(source.waist, waist, progress),
            hips: mix(source.hips, hips, progress),
            upperArms: mix(source.upperArms, upperArms, progress),
            forearms: mix(source.forearms, forearms, progress),
            thighs: mix(source.thighs, thighs, progress),
            calves: mix(source.calves, calves, progress)
        )
    }

    private func mix(_ source: Double, _ target: Double, _ progress: Double) -> Double {
        source + (target - source) * progress
    }
}
