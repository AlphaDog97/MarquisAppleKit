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
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration)
    }

    public final class Coordinator {
        private let configuration: BodyMapRendererConfiguration
        private var commandQueue: MTLCommandQueue?

        init(configuration: BodyMapRendererConfiguration) {
            self.configuration = configuration
        }

        func setup(view: MTKView) {
            guard let device = configuration.device else {
                return
            }

            commandQueue = device.makeCommandQueue()
            view.delegate = self
        }
    }
}

extension BodyMapMetalRendererView.Coordinator: MTKViewDelegate {
    public func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue?.makeCommandBuffer()
        else {
            return
        }

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}

public final class BodyMapRendererConfiguration {
    public let device: MTLDevice?
    public let prefersMetalRendering: Bool

    public init(
        device: MTLDevice? = MTLCreateSystemDefaultDevice(),
        prefersMetalRendering: Bool = true
    ) {
        self.device = device
        self.prefersMetalRendering = prefersMetalRendering
    }
}
