import SwiftUI
import XCTest
@testable import AppDesignComponents

#if canImport(UIKit)
import Metal
import UIKit
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

    func testBaseAppearanceIsOwnedByComponent() {
        XCTAssertEqual(BodyMapBaseAppearance.baseOpacity, 1)
        XCTAssertTrue(BodyMapBaseAppearance.glowEnabled)
    }

    func testAppearanceStoresRegionStyles() {
        let appearance = BodyMapAppearance(regionStyles: [
            BodyMapRegionStyle(id: .chest, color: .red)
        ])

        XCTAssertEqual(appearance.regionStyles.count, 1)
        XCTAssertEqual(appearance.regionStyles.first?.id, .chest)
    }

    func testAppearancePreservesCustomInactiveColorWhenRegionsChange() {
        let appearance = BodyMapAppearance(inactiveColor: .red)
        let updated = appearance.withRegions([
            BodyMapRegionStyle(id: .chest, color: .blue)
        ])

        XCTAssertEqual(appearance.inactiveColor, .red)
        XCTAssertEqual(updated.inactiveColor, .red)
        XCTAssertEqual(updated.regionStyles.count, 1)
    }

    func testAppearanceUpdatesRegions() {
        let appearance = BodyMapAppearance()
        let updated = appearance.withRegions([
            BodyMapRegionStyle(id: .chest, color: .red)
        ])

        XCTAssertEqual(updated.regionStyles.count, 1)
        XCTAssertEqual(updated.regionStyles.first?.id, .chest)
    }

    func testDefaultConfigurationUsesNeutralMorphology() {
        let configuration = BodyMapConfiguration()

        XCTAssertEqual(configuration.morphology, .neutral)
        XCTAssertTrue(configuration.morphology.isNeutral)
    }

    func testNeutralMorphologyPreservesSamplingCoordinates() {
        let point = CGPoint(x: 0.73, y: 0.41)

        let source = BodyMapMorphologyWarp.sourceNormalizedPoint(
            point,
            morphology: .neutral
        )

        XCTAssertEqual(source.x, point.x, accuracy: 0.000_001)
        XCTAssertEqual(source.y, point.y, accuracy: 0.000_001)
    }

    func testExpandedWaistMapsOutputTowardNeutralSource() {
        let morphology = BodyMapMorphology(waist: 1.10)
        let output = CGPoint(x: 0.68, y: 0.41)

        let source = BodyMapMorphologyWarp.sourceNormalizedPoint(
            output,
            morphology: morphology
        )

        XCTAssertLessThan(source.x, output.x)
        XCTAssertGreaterThan(source.x, 0.5)
        XCTAssertEqual(source.y, output.y, accuracy: 0.000_001)
    }

    func testUpperArmMorphologyTargetsOuterArmZoneMoreThanTorso() {
        let morphology = BodyMapMorphology(upperArms: 1.12)
        let torsoOutput = CGPoint(x: 0.58, y: 0.32)
        let armOutput = CGPoint(x: 0.82, y: 0.32)

        let torsoSource = BodyMapMorphologyWarp.sourceNormalizedPoint(
            torsoOutput,
            morphology: morphology
        )
        let armSource = BodyMapMorphologyWarp.sourceNormalizedPoint(
            armOutput,
            morphology: morphology
        )

        let torsoShift = abs(torsoOutput.x - torsoSource.x)
        let armShift = abs(armOutput.x - armSource.x)
        XCTAssertGreaterThan(armShift, torsoShift)
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
            "bodyMapBlurMask",
            "bodyMapMorphologyDistortion"
        ]

        for functionName in functionNames {
            XCTAssertNotNil(
                library.makeFunction(name: functionName),
                "Missing packaged BodyMap Metal function: \(functionName)"
            )
        }
    }

    @MainActor
    func testStaticExportProducesVisibleUIImage() throws {
        let content = BodyMap(
            model: .male,
            regions: [
                BodyMapRegionStyle(id: .chest, color: .red)
            ],
            appearance: BodyMapAppearance(inactiveColor: .gray),
            animation: BodyMapAnimationConfiguration(enabled: false)
        )
        .frame(width: 164, height: 208)
        .bodyMapRenderingMode(.staticExport)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        guard let image = renderer.uiImage else {
            XCTFail("Static export did not produce a UIImage")
            return
        }

        let bitmap = try BodyMapMaskRasterizer.rasterize(image, scale: 1)
        XCTAssertTrue(
            bitmap.bytes.contains { $0 > 0 },
            "Static export produced a fully transparent image"
        )
    }

    @MainActor
    func testMorphedStaticExportProducesVisibleUIImage() throws {
        let content = BodyMap(
            model: .female,
            regions: [
                BodyMapRegionStyle(id: .core, color: .orange)
            ],
            morphology: BodyMapMorphology(
                shoulders: 1.04,
                waist: 0.94,
                hips: 1.06,
                thighs: 1.05
            ),
            appearance: BodyMapAppearance(inactiveColor: .gray),
            animation: BodyMapAnimationConfiguration(enabled: false)
        )
        .frame(width: 164, height: 208)
        .bodyMapRenderingMode(.staticExport)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        guard let image = renderer.uiImage else {
            XCTFail("Morphed static export did not produce a UIImage")
            return
        }

        let bitmap = try BodyMapMaskRasterizer.rasterize(image, scale: 1)
        XCTAssertTrue(
            bitmap.bytes.contains { $0 > 0 },
            "Morphed static export produced a fully transparent image"
        )
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
