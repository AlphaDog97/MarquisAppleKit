#if canImport(UIKit)
import UIKit

struct BodyMapStaticImageLoader {
    enum LoadingError: Error {
        case missingAsset(String)
    }

    private let resourceResolver = BodyMapResourceResolver()

    func load(named name: String, bundle: Bundle) throws -> UIImage {
        if let pdfURL = resourceResolver.pdfURL(named: name, bundle: bundle) {
            return try BodyMapMaskRasterizer.rasterizedPDFImage(
                at: pdfURL,
                scale: 1
            )
        }

        if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            return image
        }

        throw LoadingError.missingAsset(name)
    }
}
#endif
