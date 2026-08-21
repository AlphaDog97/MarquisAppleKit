import Foundation

public extension BodyMapRegionID {
    static let shoulders = Self(rawValue: "shoulders")
    static let chest = Self(rawValue: "chest")
    static let upperBack = Self(rawValue: "upperBack")
    static let lowerBack = Self(rawValue: "lowerBack")
    static let upperArms = Self(rawValue: "upperArms")
    static let forearms = Self(rawValue: "forearms")
    static let core = Self(rawValue: "core")
    static let hips = Self(rawValue: "hips")
    static let glutes = Self(rawValue: "glutes")
    static let quadriceps = Self(rawValue: "quadriceps")
    static let hamstrings = Self(rawValue: "hamstrings")
    static let calves = Self(rawValue: "calves")
}

enum BodyMapAnatomySide: String, CaseIterable {
    case front
    case back
}

enum BodyMapAnatomyAsset: String, CaseIterable, Identifiable {
    case shoulderFront
    case chest
    case biceps
    case abdomen
    case externalOblique
    case forearmFront
    case quadriceps
    case lowerLegFront
    case shoulderBack
    case lats
    case upperBack
    case triceps
    case forearmBack
    case lowerBack
    case buttocks
    case hamstrings
    case lowerLegBack

    var id: String { rawValue }

    var side: BodyMapAnatomySide {
        switch self {
        case .shoulderFront, .chest, .biceps, .abdomen, .externalOblique,
             .forearmFront, .quadriceps, .lowerLegFront:
            .front
        case .shoulderBack, .lats, .upperBack, .triceps, .forearmBack,
             .lowerBack, .buttocks, .hamstrings, .lowerLegBack:
            .back
        }
    }

    var suffix: String {
        switch self {
        case .shoulderFront: "shoulder_front"
        case .chest: "chest"
        case .biceps: "biceps"
        case .abdomen: "abdomen"
        case .externalOblique: "external_oblique"
        case .forearmFront: "forearm_front"
        case .quadriceps: "quadriceps"
        case .lowerLegFront: "lower_leg_front"
        case .shoulderBack: "shoulder_back"
        case .lats: "lats"
        case .upperBack: "upper_back"
        case .triceps: "triceps"
        case .forearmBack: "forearm_back"
        case .lowerBack: "lower_back"
        case .buttocks: "buttocks"
        case .hamstrings: "hamstrings"
        case .lowerLegBack: "lower_leg_back"
        }
    }

    var region: BodyMapRegionID {
        switch self {
        case .shoulderFront, .shoulderBack: .shoulders
        case .chest: .chest
        case .biceps, .triceps: .upperArms
        case .forearmFront, .forearmBack: .forearms
        case .abdomen, .externalOblique: .core
        case .quadriceps: .quadriceps
        case .lowerLegFront, .lowerLegBack: .calves
        case .lats, .upperBack: .upperBack
        case .lowerBack: .lowerBack
        case .buttocks: .glutes
        case .hamstrings: .hamstrings
        }
    }
}

enum BodyMapAnatomyAssetResolver {
    static func assetName(model: BodyMapModel, asset: BodyMapAnatomyAsset) -> String {
        "\(model.resourcePrefix)_\(asset.suffix)"
    }

    static func baseShapeAssetName(model: BodyMapModel, side: BodyMapAnatomySide) -> String {
        "\(model.resourcePrefix)_body_shape_\(side.rawValue)"
    }
}

extension BodyMapModel {
    var resourcePrefix: String {
        switch self {
        case .male: "male"
        case .female: "female"
        }
    }
}
