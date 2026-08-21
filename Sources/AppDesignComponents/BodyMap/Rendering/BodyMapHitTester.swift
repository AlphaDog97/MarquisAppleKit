import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum BodyMapHitTester {
    static func region(
        at location: CGPoint,
        in size: CGSize,
        side: BodyMapAnatomySide,
        model: BodyMapModel,
        bundle: Bundle
    ) -> BodyMapRegionID? {
        guard size.width > 0,
              size.height > 0,
              location.x >= 0,
              location.x < size.width,
              location.y >= 0,
              location.y < size.height else {
            return nil
        }

        #if canImport(UIKit)
        let normalizedPoint = CGPoint(
            x: location.x / size.width,
            y: location.y / size.height
        )

        return BodyMapAnatomyAsset.allCases
            .filter { $0.side == side }
            .reversed()
            .first {
                contains(
                    normalizedPoint,
                    asset: $0,
                    model: model,
                    bundle: bundle
                )
            }?
            .region
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    private static func contains(
        _ normalizedPoint: CGPoint,
        asset: BodyMapAnatomyAsset,
        model: BodyMapModel,
        bundle: Bundle
    ) -> Bool {
        let assetName = BodyMapAnatomyAssetResolver.assetName(
            model: model,
            asset: asset
        )
        guard let image = UIImage(
            named: assetName,
            in: bundle,
            compatibleWith: nil
        ) else {
            return false
        }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.preferredRange = .standard
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 1, height: 1),
            format: format
        )
        let sampledImage = renderer.image { context in
            let width = image.size.width
            let height = image.size.height
            context.cgContext.translateBy(
                x: 0.5 - normalizedPoint.x * width,
                y: 0.5 - normalizedPoint.y * height
            )
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        guard let sample = sampledImage.cgImage else { return false }

        var pixel = [UInt8](repeating: 0, count: 4)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue

        let didRender = pixel.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) else {
                return false
            }

            context.interpolationQuality = .none
            context.draw(sample, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }

        return didRender && pixel[3] > 24
    }
    #endif
}
