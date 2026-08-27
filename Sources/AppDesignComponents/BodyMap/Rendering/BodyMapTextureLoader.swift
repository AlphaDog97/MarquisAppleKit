#if canImport(UIKit)
import Foundation
import Metal
import UIKit

struct BodyMapMaskTextureSet {
    let model: BodyMapModel
    let side: BodyMapAnatomySide
    let assets: [BodyMapAnatomyAsset]
    let assetBounds: [SIMD4<Float>]
    let masks: MTLTexture

    var width: Int { masks.width }
}

enum BodyMapMaskPrewarmer {
    static func prewarm(
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) async throws {
        let job = BodyMapMaskPrewarmJob(
            model: model,
            side: side,
            bundle: bundle
        )

        try await Task.detached(priority: .utility) {
            try job.run()
        }.value
    }
}

private final class BodyMapMaskPrewarmJob: @unchecked Sendable {
    private let model: BodyMapModel
    private let side: BodyMapAnatomySide
    private let bundle: Bundle

    init(
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) {
        self.model = model
        self.side = side
        self.bundle = bundle
    }

    func run() throws {
        let resources = BodyMapMetalResources.shared
        let loader = BodyMapTextureLoader(resources: resources)
        _ = try loader.loadMaskSet(
            model: model,
            side: side,
            bundle: bundle
        )
    }
}

final class BodyMapTextureLoader {
    enum LoadingError: Error {
        case missingAsset(String)
        case rasterizationFailed(String, Error)
        case inconsistentAssetSize(String)
        case emptyAssetMask(String)
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
        if let persisted = BodyMapMaskDiskCache.load(
            model: model,
            side: side,
            bundle: bundle,
            expectedAssetCount: assets.count
        ) {
            let result = makePersistedMaskSet(
                persisted,
                model: model,
                side: side,
                assets: assets
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

        let names = [
            BodyMapAnatomyAssetResolver.baseShapeAssetName(
                model: model,
                side: side
            )
        ] + assets.map {
            BodyMapAnatomyAssetResolver.assetName(model: model, asset: $0)
        }

        let masks = try names.map {
            try loadSourceMask(named: $0, bundle: bundle)
        }
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

        let assetMasks = Array(masks.dropFirst())
        guard assetMasks.count == assets.count else {
            preconditionFailure("BodyMap asset mask count is inconsistent")
        }
        if let emptyIndex = assetMasks.firstIndex(where: {
            $0.normalizedBounds.z <= $0.normalizedBounds.x
                || $0.normalizedBounds.w <= $0.normalizedBounds.y
        }) {
            throw LoadingError.emptyAssetMask(names[emptyIndex + 1])
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
            assetBounds: assetMasks.map(\.normalizedBounds),
            masks: texture
        )
        cache.store(
            result,
            device: device,
            bundle: bundle,
            model: model,
            side: side
        )

        BodyMapMaskDiskCache.storeInBackground(
            masks: masks,
            model: model,
            side: side,
            bundle: bundle
        )
        return result
    }

    private func makePersistedMaskSet(
        _ persisted: BodyMapPersistedMaskSet,
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        assets: [BodyMapAnatomyAsset]
    ) -> BodyMapMaskTextureSet {
        let texture = makeMaskArray(
            width: persisted.width,
            height: persisted.height,
            slices: persisted.sliceCount
        )
        persisted.storage.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            for slice in 0..<persisted.sliceCount {
                texture.replace(
                    region: MTLRegionMake2D(
                        0,
                        0,
                        persisted.width,
                        persisted.height
                    ),
                    mipmapLevel: 0,
                    slice: slice,
                    withBytes: baseAddress.advanced(
                        by: persisted.sliceByteOffset
                            + slice * persisted.bytesPerSlice
                    ),
                    bytesPerRow: persisted.width,
                    bytesPerImage: persisted.bytesPerSlice
                )
            }
        }

        return BodyMapMaskTextureSet(
            model: model,
            side: side,
            assets: assets,
            assetBounds: persisted.assetBounds,
            masks: texture
        )
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
