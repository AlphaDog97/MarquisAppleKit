#if canImport(UIKit)
import Foundation
import Metal

final class BodyMapMetalResources: @unchecked Sendable {
    static let shared = BodyMapMetalResources()

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    let downsamplePipeline: MTLComputePipelineState
    let blurPipeline: MTLComputePipelineState

    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            preconditionFailure("BodyMap requires Metal support")
        }

        do {
            let library = try Self.makeLibrary(device: device)
            guard let vertex = library.makeFunction(name: "bodyMapVertex"),
                  let fragment = library.makeFunction(name: "bodyMapFragment"),
                  let downsample = library.makeFunction(name: "bodyMapDownsampleMask"),
                  let blur = library.makeFunction(name: "bodyMapBlurMask") else {
                preconditionFailure("BodyMap Metal functions are missing")
            }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.label = "BodyMap anatomy pipeline"
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb

            self.renderPipeline = try device.makeRenderPipelineState(
                descriptor: descriptor
            )
            self.downsamplePipeline = try device.makeComputePipelineState(
                function: downsample
            )
            self.blurPipeline = try device.makeComputePipelineState(
                function: blur
            )
        } catch {
            preconditionFailure("Unable to create BodyMap Metal pipelines: \(error)")
        }

        self.device = device
        self.commandQueue = commandQueue
    }

    private static func makeLibrary(device: MTLDevice) throws -> MTLLibrary {
        let shaderURL = Bundle.module.url(
            forResource: "BodyMapShaders",
            withExtension: "metal",
            subdirectory: "BodyMap"
        ) ?? Bundle.module.url(
            forResource: "BodyMapShaders",
            withExtension: "metal"
        )

        guard let shaderURL else {
            throw BodyMapMetalResourceError.missingShader
        }

        let source = try String(contentsOf: shaderURL, encoding: .utf8)
        return try device.makeLibrary(source: source, options: nil)
    }
}

private enum BodyMapMetalResourceError: Error {
    case missingShader
}
#endif
