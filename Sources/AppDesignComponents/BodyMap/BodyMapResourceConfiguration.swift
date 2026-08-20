import Foundation

public struct BodyMapResourceConfiguration: Sendable {
    public let model: BodyMapModel
    let textureName: String

    public init(model: BodyMapModel) {
        self.model = model
        self.textureName = BodyMapResourceResolver().textureName(for: model)
    }
}
