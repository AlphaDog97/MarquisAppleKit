#if canImport(UIKit)
import CoreGraphics
import UIKit

struct BodyMapMaskBitmap {
    let width: Int
    let height: Int
    let bytes: [UInt8]
}

enum BodyMapMaskRasterizer {
    static let rasterScale: CGFloat = 2

    enum RasterizationError: Error {
        case invalidImageSize(CGSize)
        case invalidPDF(URL)
        case missingPDFPage(URL)
        case missingRasterizedImage
        case bitmapContextCreationFailed
    }

    static func rasterize(
        _ image: UIImage,
        scale: CGFloat = rasterScale
    ) throws -> BodyMapMaskBitmap {
        guard image.size.width > 0, image.size.height > 0 else {
            throw RasterizationError.invalidImageSize(image.size)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let rasterized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        guard let cgImage = rasterized.cgImage else {
            throw RasterizationError.missingRasterizedImage
        }

        return try alphaBitmap(from: cgImage)
    }

    static func rasterizePDF(
        at url: URL,
        scale: CGFloat = rasterScale
    ) throws -> BodyMapMaskBitmap {
        guard let document = CGPDFDocument(url as CFURL) else {
            throw RasterizationError.invalidPDF(url)
        }
        guard let page = document.page(at: 1) else {
            throw RasterizationError.missingPDFPage(url)
        }

        let pageBounds = page.getBoxRect(.mediaBox).standardized
        guard pageBounds.width > 0, pageBounds.height > 0 else {
            throw RasterizationError.invalidImageSize(pageBounds.size)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: pageBounds.size, format: format)
        let rasterized = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: pageBounds.height)
            cgContext.scaleBy(x: 1, y: -1)
            cgContext.translateBy(x: -pageBounds.minX, y: -pageBounds.minY)
            cgContext.drawPDFPage(page)
            cgContext.restoreGState()
        }
        guard let cgImage = rasterized.cgImage else {
            throw RasterizationError.missingRasterizedImage
        }

        return try alphaBitmap(from: cgImage)
    }

    private static func alphaBitmap(from cgImage: CGImage) throws -> BodyMapMaskBitmap {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rgba = [UInt8](repeating: 0, count: bytesPerRow * height)

        let rendered = rgba.withUnsafeMutableBytes { buffer in
            guard let address = buffer.baseAddress,
                  let context = CGContext(
                    data: address,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                        | CGBitmapInfo.byteOrder32Big.rawValue
                  ) else {
                return false
            }

            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            context.draw(
                cgImage,
                in: CGRect(x: 0, y: 0, width: width, height: height)
            )
            return true
        }

        guard rendered else {
            throw RasterizationError.bitmapContextCreationFailed
        }

        var alpha = [UInt8](repeating: 0, count: width * height)
        for destinationRow in 0..<height {
            let sourceRow = height - 1 - destinationRow
            for column in 0..<width {
                alpha[destinationRow * width + column] = rgba[
                    sourceRow * bytesPerRow + column * bytesPerPixel + 3
                ]
            }
        }

        return BodyMapMaskBitmap(width: width, height: height, bytes: alpha)
    }
}
#endif
