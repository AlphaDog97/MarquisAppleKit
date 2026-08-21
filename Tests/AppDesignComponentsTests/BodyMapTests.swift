import XCTest
@testable import AppDesignComponents

#if canImport(UIKit)
import Metal
#endif

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

    func testAppearancePreservesGlobalGlowSwitchWhenRegionsChange() {
        let appearance = BodyMapAppearance(glowEnabled: false)
        let updated = appearance.withRegions([
            BodyMapRegionStyle(id: .chest, color: .red)
        ])

        XCTAssertFalse(updated.glowEnabled)
        XCTAssertEqual(updated.regionStyles.count, 1)
        XCTAssertEqual(updated.regionStyles.first?.id, .chest)
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

    func testPackageContainsEveryHumanBodyPDF() {
        let resolver = BodyMapResourceResolver()
        let bundle = BodyMapResourceConfiguration(model: .male).bundle

        for model in [BodyMapModel.male, .female] {
            for side in [BodyMapAnatomySide.front, .back] {
                let baseName = BodyMapAnatomyAssetResolver.baseShapeAssetName(
                    model: model,
                    side: side
                )
                XCTAssertNotNil(
                    resolver.pdfURL(named: baseName, bundle: bundle),
                    "Missing packaged BodyMap resource: \(baseName).pdf"
                )
            }

            for asset in BodyMapAnatomyAsset.allCases {
                let name = BodyMapAnatomyAssetResolver.assetName(
                    model: model,
                    asset: asset
                )
                XCTAssertNotNil(
                    resolver.pdfURL(named: name, bundle: bundle),
                    "Missing packaged BodyMap resource: \(name).pdf"
                )
            }
        }
    }

#if canImport(UIKit)
    func testPackageContainsBodyMapMetalFunctions() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            XCTFail("BodyMap requires a Metal-capable device")
            return
        }

        let library = try BodyMapMetalResources.makeLibrary(device: device)
        let functionNames = [
            "bodyMapVertex",
            "bodyMapFragment",
            "bodyMapDownsampleMask",
            "bodyMapBlurMask"
        ]

        for functionName in functionNames {
            XCTAssertNotNil(
                library.makeFunction(name: functionName),
                "Missing packaged BodyMap Metal function: \(functionName)"
            )
        }
    }
#endif

    func testCanonicalRegionIdentifiersMatchSomaTrackRawValues() {
        XCTAssertEqual(BodyMapRegionID.shoulders.rawValue, "shoulders")
        XCTAssertEqual(BodyMapRegionID.upperBack.rawValue, "upperBack")
        XCTAssertEqual(BodyMapRegionID.lowerBack.rawValue, "lowerBack")
        XCTAssertEqual(BodyMapRegionID.upperArms.rawValue, "upperArms")
        XCTAssertEqual(BodyMapRegionID.quadriceps.rawValue, "quadriceps")
    }
}
