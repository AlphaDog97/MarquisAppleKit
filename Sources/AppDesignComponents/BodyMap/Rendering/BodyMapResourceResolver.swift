import Foundation

public struct BodyMapResourceResolver {
    public init() {}

    public func textureName(for model: BodyMapModel) -> String {
        switch model {
        case .male:
            return "body_map_male"
        case .female:
            return "body_map_female"
        }
    }
}
