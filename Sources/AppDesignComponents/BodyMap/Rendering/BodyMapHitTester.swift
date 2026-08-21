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

        let mask: BodyMapMaskBitmap
        do {
            if let pdfURL = BodyMapResourceResolver().pdfURL(
                named: assetName,
                bundle: bundle
            ) {
                mask = try BodyMapMaskRasterizer.rasterizePDF(
                    at: pdfURL,
                    scale: 1
                )
            } else if let image = UIImage(
                named: assetName,
                in: bundle,
                compatibleWith: nil
            ) {
                mask = try BodyMapMaskRasterizer.rasterize(
                    image,
                    scale: 1
                )
            } else {
                return false
            }
        } catch {
            return false
        }

        let x = min(
            max(Int(normalizedPoint.x * CGFloat(mask.width)), 0),
            mask.width - 1
        )
        let y = min(
            max(Int(normalizedPoint.y * CGFloat(mask.height)), 0),
            mask.height - 1
        )

        return mask.bytes[y * mask.width + x] > 24
    }
    #endif
}
