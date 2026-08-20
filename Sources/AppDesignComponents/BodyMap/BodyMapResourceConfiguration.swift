import Foundation

public struct BodyMapResourceConfiguration {
    public let model: BodyMapModel
    public let textureName: String

    public init(
        model: BodyMapModel,
        resolver: BodyMapResourceResolver = .init()
    ) {
        self.model = model
        self.textureName = resolver.textureName(for: model)
    }
}
