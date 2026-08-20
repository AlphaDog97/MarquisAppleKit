import Foundation

public protocol BodyMapTextureProvider {
    func textureName(for model: BodyMapModel) -> String
    func textureName(for region: BodyMapRegionID) -> String
}

public struct DefaultBodyMapTextureProvider: BodyMapTextureProvider {
    public init() {}

    public func textureName(for model: BodyMapModel) -> String {
        switch model {
        case .male:
            return "body_map_male"
        case .female:
            return "body_map_female"
        }
    }

    public func textureName(for region: BodyMapRegionID) -> String {
        "body_region_\(region.rawValue)"
    }
}
