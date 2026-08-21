#if canImport(UIKit)
import Foundation
import Metal
import UIKit

struct BodyMapMaskTextureSet {
    let model: BodyMapModel
    let side: BodyMapAnatomySide
    let assets: [BodyMapAnatomyAsset]
    let masks: MTLTexture

    var width: Int { masks.width }
}

final class BodyMapTextureLoader {
    enum LoadingError: Error {
        case missingAsset(String)
        case rasterizationFailed(String, Error)
        case inconsistentAssetSize(String)
    }

    private let device: MTLDevice
    private let cache: BodyMapMetalTextureCache
    private let resourceResolver = BodyMapResourceResolver()

    init(
        resources: BodyMapMetalResources,
        cache: BodyMapMetalTextureCache = .shared
    ) {
        self.device = resources.device
        self.cache = cache
    }

    func loadMaskSet(
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) throws -> BodyMapMaskTextureSet {
        if let cached = cache.maskSet(
            device: device,
            bundle: bundle,
            model: model,
            side: side
        ) {
            return cached
        }

        let assets = BodyMapAnatomyAsset.allCases.filter { $0.side == side }
        let names = [
            BodyMapAnatomyAssetResolver.baseShapeAssetName(
                model: model,
                side: side
            )
        ] + assets.map {
            BodyMapAnatomyAssetResolver.assetName(model: model, asset: $0)
        }

        let masks = try names.map { try loadSourceMask(named: $0, bundle: bundle) }
        guard let first = masks.first else {
            preconditionFailure("BodyMap mask manifest cannot be empty")
        }
        guard zip(names, masks).allSatisfy({ _, mask in
            mask.width == first.width && mask.height == first.height
        }) else {
            let mismatch = zip(names, masks).first {
                $0.1.width != first.width || $0.1.height != first.height
            }
            throw LoadingError.inconsistentAssetSize(mismatch?.0 ?? "unknown")
        }

        let texture = makeMaskArray(
            width: first.width,
            height: first.height,
            slices: masks.count
        )
        for (index, mask) in masks.enumerated() {
            upload(mask, to: texture, slice: index)
        }

        let result = BodyMapMaskTextureSet(
            model: model,
            side: side,
            assets: assets,
            masks: texture
        )
        cache.store(
            result,
            device: device,
            bundle: bundle,
            model: model,
            side: side
        )
        return result
    }

    private func loadSourceMask(
        named name: String,
        bundle: Bundle
    ) throws -> BodyMapMaskBitmap {
        do {
            if let pdfURL = resourceResolver.pdfURL(named: name, bundle: bundle) {
                return try BodyMapMaskRasterizer.rasterizePDF(at: pdfURL)
            }

            if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
                return try BodyMapMaskRasterizer.rasterize(image)
            }

            throw LoadingError.missingAsset(name)
        } catch let error as LoadingError {
            throw error
        } catch {
            throw LoadingError.rasterizationFailed(name, error)
        }
    }

    private func makeMaskArray(
        width: Int,
        height: Int,
        slices: Int
    ) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2DArray
        descriptor.pixelFormat = .r8Unorm
        descriptor.width = width
        descriptor.height = height
        descriptor.arrayLength = slices
        descriptor.storageMode = .shared
        descriptor.usage = .shaderRead

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            preconditionFailure("Unable to allocate BodyMap mask texture array")
        }
        return texture
    }

    private func upload(
        _ mask: BodyMapMaskBitmap,
        to texture: MTLTexture,
        slice: Int
    ) {
        mask.bytes.withUnsafeBytes { bytes in
            guard let address = bytes.baseAddress else { return }
            texture.replace(
                region: MTLRegionMake2D(0, 0, mask.width, mask.height),
                mipmapLevel: 0,
                slice: slice,
                withBytes: address,
                bytesPerRow: mask.width,
                bytesPerImage: mask.width * mask.height
            )
        }
    }
}
#endif
