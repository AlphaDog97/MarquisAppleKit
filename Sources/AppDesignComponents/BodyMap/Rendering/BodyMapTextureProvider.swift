import Foundation

public protocol BodyMapTextureProvider {
    func textureName(for region: BodyMapRegionID) -> String
}

public struct DefaultBodyMapTextureProvider: BodyMapTextureProvider {
    public init() {}

    public func textureName(for region: BodyMapRegionID) -> String {
        region.rawValue
    }
}
