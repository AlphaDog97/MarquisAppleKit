#if canImport(UIKit)
import CoreGraphics
import UIKit

struct BodyMapMaskBitmap {
    let width: Int
    let height: Int
    let bytes: [UInt8]
    let normalizedBounds: SIMD4<Float>
}

enum BodyMapMaskRasterizer {
    static let rasterScale: CGFloat = 2

    enum RasterizationError: Error {
        case invalidImageSize(CGSize)
        case invalidPDF(URL)
        case missingPDFPage(URL)
        case missingSourceImage
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
        guard let cgImage = image.cgImage else {
            throw RasterizationError.missingSourceImage
        }

        let width = Int((image.size.width * scale).rounded())
        let height = Int((image.size.height * scale).rounded())
        return try alphaBitmap(
            from: cgImage,
            width: width,
            height: height
        )
    }

    static func rasterizePDF(
        at url: URL,
        scale: CGFloat = rasterScale
    ) throws -> BodyMapMaskBitmap {
        let rasterized = try rasterizedPDFImage(at: url, scale: scale)
        guard let cgImage = rasterized.cgImage else {
            throw RasterizationError.missingRasterizedImage
        }
        return try alphaBitmap(
            from: cgImage,
            width: cgImage.width,
            height: cgImage.height
        )
    }

    static func rasterizedPDFImage(
        at url: URL,
        scale: CGFloat = rasterScale
    ) throws -> UIImage {
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
        guard rasterized.cgImage != nil else {
            throw RasterizationError.missingRasterizedImage
        }
        return rasterized
    }

    private static func alphaBitmap(
        from cgImage: CGImage,
        width: Int,
        height: Int
    ) throws -> BodyMapMaskBitmap {
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

            context.interpolationQuality = .high
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
        var minimumColumn = width
        var minimumRow = height
        var maximumColumn = -1
        var maximumRow = -1

        alpha.withUnsafeMutableBytes { destination in
            rgba.withUnsafeBytes { source in
                guard let destinationAddress = destination.baseAddress,
                      let sourceAddress = source.baseAddress else {
                    return
                }

                for destinationRow in 0..<height {
                    let sourceRow = height - 1 - destinationRow
                    let sourceRowAddress = sourceAddress.advanced(
                        by: sourceRow * bytesPerRow
                    )
                    let destinationRowAddress = destinationAddress.advanced(
                        by: destinationRow * width
                    )

                    for column in 0..<width {
                        let value = sourceRowAddress.load(
                            fromByteOffset: column * bytesPerPixel + 3,
                            as: UInt8.self
                        )
                        destinationRowAddress.storeBytes(
                            of: value,
                            toByteOffset: column,
                            as: UInt8.self
                        )

                        guard value > 0 else { continue }
                        minimumColumn = min(minimumColumn, column)
                        minimumRow = min(minimumRow, destinationRow)
                        maximumColumn = max(maximumColumn, column)
                        maximumRow = max(maximumRow, destinationRow)
                    }
                }
            }
        }

        let normalizedBounds: SIMD4<Float>
        if maximumColumn >= minimumColumn,
           maximumRow >= minimumRow {
            normalizedBounds = SIMD4(
                Float(minimumColumn) / Float(width),
                Float(minimumRow) / Float(height),
                Float(maximumColumn + 1) / Float(width),
                Float(maximumRow + 1) / Float(height)
            )
        } else {
            normalizedBounds = .zero
        }

        return BodyMapMaskBitmap(
            width: width,
            height: height,
            bytes: alpha,
            normalizedBounds: normalizedBounds
        )
    }
}
#endif
