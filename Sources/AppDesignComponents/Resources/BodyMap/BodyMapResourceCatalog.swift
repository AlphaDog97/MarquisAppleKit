import Foundation

public enum BodyMapResourceCatalog {
    public static let maleTexture = "body_map_male"
    public static let femaleTexture = "body_map_female"

    public static func regionTexture(_ region: BodyMapRegionID) -> String {
        "body_region_\(region.rawValue)"
    }
}
