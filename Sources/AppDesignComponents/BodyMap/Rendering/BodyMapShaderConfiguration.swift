import Foundation

struct BodyMapShaderUniform {
    var intensity: Float
    var glowEnergy: Float
    var shadowEnergy: Float

    init(
        intensity: Float,
        glowEnergy: Float,
        shadowEnergy: Float
    ) {
        self.intensity = intensity
        self.glowEnergy = glowEnergy
        self.shadowEnergy = shadowEnergy
    }
}

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

    var metalUniform: BodyMapShaderUniform {
        BodyMapShaderUniform(
            intensity: Float(intensity),
            glowEnergy: Float(glowEnergy),
            shadowEnergy: Float(shadowEnergy)
        )
    }
}
