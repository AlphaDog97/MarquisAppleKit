#if canImport(UIKit)
import MetalKit
import SwiftUI
import UIKit

struct BodyMapMetalSurface: UIViewRepresentable {
    let state: BodyMapMetalRenderState
    let bundle: Bundle
    let animation: BodyMapAnimationConfiguration
    let reveal: BodyMapRevealRequest?
    let onFirstFrameRendered: (() -> Void)?
    let onRevealCompleted: ((UUID) -> Void)?

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
        view.contentScaleFactor = min(UIScreen.main.scale, 2)
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        renderer.attach(
            to: view,
            onFirstFrameRendered: onFirstFrameRendered
        )
        renderer.apply(
            state,
            bundle: bundle,
            animationsEnabled: animation.enabled,
            transitionDuration: animation.transitionDuration,
            reveal: reveal,
            onRevealCompleted: onRevealCompleted
        )
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer.apply(
            state,
            bundle: bundle,
            animationsEnabled: animation.enabled,
            transitionDuration: animation.transitionDuration,
            reveal: reveal,
            onRevealCompleted: onRevealCompleted
        )
    }

    @MainActor
    final class Coordinator {
        let renderer = BodyMapMetalRenderer()
    }
}
#endif
