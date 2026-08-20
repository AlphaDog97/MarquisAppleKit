import Foundation

public struct BodyMapShaderConfiguration: Sendable {
    public let intensity: Double
    public let glowEnergy: Double
    public let shadowEnergy: Double

    public init(
        intensity: Double = 1,
        glowEnergy: Double = 0,
        shadowEnergy: Double = 0
    ) {
        self.intensity = intensity
        self.glowEnergy = glowEnergy
        self.shadowEnergy = shadowEnergy
    }
}
