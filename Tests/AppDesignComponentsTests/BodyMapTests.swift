import XCTest
@testable import AppDesignComponents

final class BodyMapTests: XCTestCase {
    func testShaderConfigurationCreatesMetalUniform() {
        let configuration = BodyMapShaderConfiguration(
            intensity: 0.8,
            glowEnergy: 0.4,
            shadowEnergy: 0.2
        )

        let uniform = configuration.metalUniform

        XCTAssertEqual(uniform.intensity, 0.8)
        XCTAssertEqual(uniform.glowEnergy, 0.4)
        XCTAssertEqual(uniform.shadowEnergy, 0.2)
    }

    func testAnatomyManifestMatchesSomaTrackSides() {
        let front = BodyMapAnatomyAsset.allCases.filter { $0.side == .front }
        let back = BodyMapAnatomyAsset.allCases.filter { $0.side == .back }

        XCTAssertEqual(front.count, 8)
        XCTAssertEqual(back.count, 9)
        XCTAssertEqual(BodyMapAnatomyAsset.biceps.region, .upperArms)
        XCTAssertEqual(BodyMapAnatomyAsset.triceps.region, .upperArms)
        XCTAssertEqual(BodyMapAnatomyAsset.externalOblique.region, .core)
        XCTAssertEqual(BodyMapAnatomyAsset.buttocks.region, .glutes)
    }

    func testAnatomyAssetNamesMatchSomaTrackCatalog() {
        XCTAssertEqual(
            BodyMapAnatomyAssetResolver.assetName(
                model: .female,
                asset: .shoulderFront
            ),
            "female_shoulder_front"
        )
        XCTAssertEqual(
            BodyMapAnatomyAssetResolver.baseShapeAssetName(
                model: .male,
                side: .back
            ),
            "male_body_shape_back"
        )
    }

    func testCanonicalRegionIdentifiersMatchSomaTrackRawValues() {
        XCTAssertEqual(BodyMapRegionID.shoulders.rawValue, "shoulders")
        XCTAssertEqual(BodyMapRegionID.upperBack.rawValue, "upperBack")
        XCTAssertEqual(BodyMapRegionID.lowerBack.rawValue, "lowerBack")
        XCTAssertEqual(BodyMapRegionID.upperArms.rawValue, "upperArms")
        XCTAssertEqual(BodyMapRegionID.quadriceps.rawValue, "quadriceps")
    }
}
