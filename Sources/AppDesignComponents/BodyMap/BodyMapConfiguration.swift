import Foundation

public struct BodyMapConfiguration: Sendable {
    public let model: BodyMapModel
    public let morphology: BodyMapMorphology
    public let shader: BodyMapShaderConfiguration
    public let resources: BodyMapResourceConfiguration

    public init(
        model: BodyMapModel = .male,
        morphology: BodyMapMorphology = .neutral,
        shader: BodyMapShaderConfiguration = .init(),
        resources: BodyMapResourceConfiguration? = nil
    ) {
        self.model = model
        self.morphology = morphology
        self.shader = shader
        self.resources = resources ?? BodyMapResourceConfiguration(model: model)
    }
}
