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
        return view
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
    }
}

public final class BodyMapRendererConfiguration {
    public let device: MTLDevice?

    public init(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        self.device = device
    }
}
