import SwiftUI
import MetalKit

public final class BodyMapRendererConfiguration {
    public let prefersMetalRendering: Bool

    public init(prefersMetalRendering: Bool = true) {
        self.prefersMetalRendering = prefersMetalRendering
    }
}

public struct BodyMapMetalRendererView: UIViewRepresentable {
    private let configuration: BodyMapRendererConfiguration

    public init(configuration: BodyMapRendererConfiguration = .init()) {
        self.configuration = configuration
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        return view
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
    }
}
