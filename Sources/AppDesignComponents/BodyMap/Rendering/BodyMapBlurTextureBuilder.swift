#if canImport(UIKit)
import Metal

struct BodyMapBlurTextureSet {
    let glow: MTLTexture
    let shadow: MTLTexture
    let selection: MTLTexture
}

final class BodyMapBlurTextureBuilder {
    enum BuildError: Error {
        case commandEncodingFailed
    }

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let downsamplePipeline: MTLComputePipelineState
    private let blurPipeline: MTLComputePipelineState

    init(resources: BodyMapMetalResources) {
        self.device = resources.device
        self.commandQueue = resources.commandQueue
        self.downsamplePipeline = resources.downsamplePipeline
        self.blurPipeline = resources.blurPipeline
    }

    func makeTextures(
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
            throw BuildError.commandEncodingFailed
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
            radius: max(
                glowRadius
                    * radiusScale
                    * Float(BodyMapGlowMetrics.spreadScale),
                0
            )
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
        descriptor.storageMode = .private
        descriptor.usage = [.shaderRead, .shaderWrite]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            preconditionFailure("Unable to allocate BodyMap blur texture array")
        }
        return texture
    }

    private func encodeDownsample(
        commandBuffer: MTLCommandBuffer,
        source: MTLTexture,
        destination: MTLTexture
    ) throws {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw BuildError.commandEncodingFailed
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
            throw BuildError.commandEncodingFailed
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
