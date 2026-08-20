import MetalKit
import SwiftUI

public struct BodyMapMetalRendererView: UIViewRepresentable {
    private let configuration: BodyMapRendererConfiguration

    public init(configuration: BodyMapRendererConfiguration = .init()) {
        self.configuration = configuration
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = configuration.device
        view.framebufferOnly = false
        view.enableSetNeedsDisplay = false
        context.coordinator.setup(view: view)
        return view
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.update(configuration: configuration)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration)
    }

    public final class Coordinator {
        private var configuration: BodyMapRendererConfiguration
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var texture: MTLTexture?

        init(configuration: BodyMapRendererConfiguration) {
            self.configuration = configuration
        }

        func setup(view: MTKView) {
            guard let device = configuration.device else { return }
            commandQueue = device.makeCommandQueue()
            reloadResources(device: device)
            pipelineState = makePipelineState(device: device, view: view)
            view.delegate = self
        }

        func update(configuration: BodyMapRendererConfiguration) {
            let shouldReloadTexture = self.configuration.textureName != configuration.textureName
            self.configuration = configuration

            guard shouldReloadTexture,
                  let device = configuration.device else {
                return
            }

            texture = BodyMapTextureLoader(device: device)
                .loadTexture(named: configuration.textureName)
        }

        private func reloadResources(device: MTLDevice) {
            texture = BodyMapTextureLoader(device: device)
                .loadTexture(named: configuration.textureName)
        }

        private func makePipelineState(device: MTLDevice, view: MTKView) -> MTLRenderPipelineState? {
            guard let library = device.makeDefaultLibrary() else { return nil }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "bodyMapVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "bodyMapFragment")
            descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

            return try? device.makeRenderPipelineState(descriptor: descriptor)
        }
    }
}

extension BodyMapMetalRendererView.Coordinator: MTKViewDelegate {
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        if let pipelineState {
            encoder.setRenderPipelineState(pipelineState)
        }

        if let texture {
            encoder.setFragmentTexture(texture, index: 0)
        }

        var shader = configuration.shaderConfiguration.metalUniform
        encoder.setFragmentBytes(
            &shader,
            length: MemoryLayout<BodyMapShaderUniform>.stride,
            index: 1
        )

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
