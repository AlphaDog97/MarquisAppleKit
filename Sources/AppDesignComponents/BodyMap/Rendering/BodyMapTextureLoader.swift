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

struct BodyMapBlurTextureSet {
    let glow: MTLTexture
    let shadow: MTLTexture
    let selection: MTLTexture
}

final class BodyMapTextureLoader {
    enum LoadingError: Error {
        case missingAsset(String)
        case rasterizationFailed(String, Error)
        case inconsistentAssetSize(String)
        case commandEncodingFailed
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let downsamplePipeline: MTLComputePipelineState
    private let blurPipeline: MTLComputePipelineState
    private let cache: BodyMapMetalTextureCache

    init(
        resources: BodyMapMetalResources,
        cache: BodyMapMetalTextureCache = .shared
    ) {
        self.device = resources.device
        self.commandQueue = resources.commandQueue
        self.downsamplePipeline = resources.downsamplePipeline
        self.blurPipeline = resources.blurPipeline
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

        guard let firstName = names.first else {
            throw LoadingError.commandEncodingFailed
        }
        let first = try loadSourceMask(named: firstName, bundle: bundle)
        let texture = makeMaskArray(
            width: first.width,
            height: first.height,
            slices: names.count,
            storageMode: .shared
        )
        upload(first, to: texture, slice: 0)

        for (index, name) in names.dropFirst().enumerated() {
            let mask = try loadSourceMask(named: name, bundle: bundle)
            guard mask.width == first.width, mask.height == first.height else {
                throw LoadingError.inconsistentAssetSize(name)
            }
            upload(mask, to: texture, slice: index + 1)
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

    func makeBlurTextures(
        from source: MTLTexture,
        glowRadius: Float,
        shadowRadius: Float,
        selectionRadius: Float
    ) throws -> BodyMapBlurTextureSet {
        let scale: Float = 0.25
        let width = max(Int((Float(source.width) * scale).rounded(.up)), 1)
        let height = max(Int((Float(source.height) * scale).rounded(.up)), 1)
        let lowResolution = makeMaskArray(
            width: width,
            height: height,
            slices: source.arrayLength
        )
        let temporary = makeMaskArray(
            width: width,
            height: height,
            slices: source.arrayLength
        )
        let glow = makeMaskArray(width: width, height: height, slices: source.arrayLength)
        let shadow = makeMaskArray(width: width, height: height, slices: source.arrayLength)
        let selection = makeMaskArray(width: width, height: height, slices: source.arrayLength)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw LoadingError.commandEncodingFailed
        }
        try encodeDownsample(
            commandBuffer: commandBuffer,
            source: source,
            destination: lowResolution
        )

        let radiusScale = Float(width) / Float(max(source.width, 1))
        try encodeBlurPair(
            commandBuffer: commandBuffer,
            source: lowResolution,
            temporary: temporary,
            destination: glow,
            radius: max(glowRadius * radiusScale, 0)
        )
        try encodeBlurPair(
            commandBuffer: commandBuffer,
            source: lowResolution,
            temporary: temporary,
            destination: shadow,
            radius: max(shadowRadius * radiusScale, 0)
        )
        try encodeBlurPair(
            commandBuffer: commandBuffer,
            source: lowResolution,
            temporary: temporary,
            destination: selection,
            radius: max(selectionRadius * radiusScale, 0)
        )
        commandBuffer.commit()

        return .init(glow: glow, shadow: shadow, selection: selection)
    }

    private func loadSourceMask(
        named name: String,
        bundle: Bundle
    ) throws -> BodyMapMaskBitmap {
        guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else {
            throw LoadingError.missingAsset(name)
        }

        do {
            return try BodyMapMaskRasterizer.rasterize(image)
        } catch {
            throw LoadingError.rasterizationFailed(name, error)
        }
    }

    private func makeMaskArray(
        width: Int,
        height: Int,
        slices: Int,
        storageMode: MTLStorageMode = .private
    ) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2DArray
        descriptor.pixelFormat = .r8Unorm
        descriptor.width = width
        descriptor.height = height
        descriptor.arrayLength = slices
        descriptor.storageMode = storageMode
        descriptor.usage = [.shaderRead, .shaderWrite]

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

    private func encodeDownsample(
        commandBuffer: MTLCommandBuffer,
        source: MTLTexture,
        destination: MTLTexture
    ) throws {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw LoadingError.commandEncodingFailed
        }
        encoder.setComputePipelineState(downsamplePipeline)
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
        dispatch(
            encoder: encoder,
            pipeline: downsamplePipeline,
            width: destination.width,
            height: destination.height,
            depth: destination.arrayLength
        )
        encoder.endEncoding()
    }

    private func encodeBlurPair(
        commandBuffer: MTLCommandBuffer,
        source: MTLTexture,
        temporary: MTLTexture,
        destination: MTLTexture,
        radius: Float
    ) throws {
        try encodeBlur(
            commandBuffer: commandBuffer,
            source: source,
            destination: temporary,
            radius: radius,
            axis: SIMD2(1, 0)
        )
        try encodeBlur(
            commandBuffer: commandBuffer,
            source: temporary,
            destination: destination,
            radius: radius,
            axis: SIMD2(0, 1)
        )
    }

    private func encodeBlur(
        commandBuffer: MTLCommandBuffer,
        source: MTLTexture,
        destination: MTLTexture,
        radius: Float,
        axis: SIMD2<Float>
    ) throws {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw LoadingError.commandEncodingFailed
        }
        var uniforms = BodyMapBlurUniforms(radius: radius, axis: axis)
        encoder.setComputePipelineState(blurPipeline)
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
        encoder.setBytes(
            &uniforms,
            length: MemoryLayout<BodyMapBlurUniforms>.stride,
            index: 0
        )
        dispatch(
            encoder: encoder,
            pipeline: blurPipeline,
            width: source.width,
            height: source.height,
            depth: source.arrayLength
        )
        encoder.endEncoding()
    }

    private func dispatch(
        encoder: MTLComputeCommandEncoder,
        pipeline: MTLComputePipelineState,
        width: Int,
        height: Int,
        depth: Int
    ) {
        let threadWidth = pipeline.threadExecutionWidth
        let threadHeight = max(
            pipeline.maxTotalThreadsPerThreadgroup / threadWidth,
            1
        )
        encoder.dispatchThreads(
            MTLSize(width: width, height: height, depth: depth),
            threadsPerThreadgroup: MTLSize(
                width: threadWidth,
                height: threadHeight,
                depth: 1
            )
        )
    }
}

private struct BodyMapBlurUniforms {
    var radius: Float
    var padding: Float = 0
    var axis: SIMD2<Float>
}
#endif
