import Foundation

public struct BodyMapConfiguration: Sendable {
    public let model: BodyMapModel
    public let shader: BodyMapShaderConfiguration
    public let resources: BodyMapResourceConfiguration

    public init(
        model: BodyMapModel = .male,
        shader: BodyMapShaderConfiguration = .init(),
        resources: BodyMapResourceConfiguration? = nil
    ) {
        self.model = model
        self.shader = shader
        self.resources = resources ?? BodyMapResourceConfiguration(model: model)
    }
}
