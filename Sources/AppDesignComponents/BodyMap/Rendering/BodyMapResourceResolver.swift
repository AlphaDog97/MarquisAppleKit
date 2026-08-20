import Foundation

struct BodyMapResourceResolver {
    init() {}

    func textureName(for model: BodyMapModel) -> String {
        switch model {
        case .male:
            return "body_map_male"
        case .female:
            return "body_map_female"
        }
    }
}
