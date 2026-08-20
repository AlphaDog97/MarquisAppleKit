import Foundation

public struct BodyMapShaderUniform {
    public var intensity: Float
    public var glowEnergy: Float
    public var shadowEnergy: Float

    public init(
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

    public var metalUniform: BodyMapShaderUniform {
        BodyMapShaderUniform(
            intensity: Float(intensity),
            glowEnergy: Float(glowEnergy),
            shadowEnergy: Float(shadowEnergy)
        )
    }
}
