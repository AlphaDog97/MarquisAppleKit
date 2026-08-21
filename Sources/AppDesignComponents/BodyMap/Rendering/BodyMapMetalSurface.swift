#if canImport(UIKit)
import MetalKit
import SwiftUI

struct BodyMapMetalSurface: UIViewRepresentable {
    let state: BodyMapMetalRenderState
    let bundle: Bundle
    let animation: BodyMapAnimationConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let renderer = context.coordinator.renderer
        let view = MTKView(frame: .zero, device: renderer.device)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        renderer.attach(to: view)
        renderer.apply(
            state,
            bundle: bundle,
            animationsEnabled: false,
            transitionDuration: 0
        )
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer.apply(
            state,
            bundle: bundle,
            animationsEnabled: animation.enabled,
            transitionDuration: animation.transitionDuration
        )
    }

    final class Coordinator {
        let renderer = BodyMapMetalRenderer()
    }
}
#endif
