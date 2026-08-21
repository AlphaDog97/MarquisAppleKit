#if canImport(UIKit)
import MetalKit
import QuartzCore

final class BodyMapMetalRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice

    private let resources: BodyMapMetalResources
    private let textureLoader: BodyMapTextureLoader
    private weak var view: MTKView?

    private var targetState: BodyMapMetalRenderState?
    private var transition: Transition?
    private var maskSet: BodyMapMaskTextureSet?
    private var blurSet: BodyMapBlurTextureSet?
    private var blurConfiguration: BlurConfiguration?
    private var resourceBundle: Bundle = .main
    private var resourceBundlePath = Bundle.main.bundlePath

    override init() {
        let resources = BodyMapMetalResources.shared
        self.resources = resources
        self.device = resources.device
        self.textureLoader = BodyMapTextureLoader(resources: resources)
        super.init()
    }

    func attach(to view: MTKView) {
        self.view = view
        view.delegate = self
    }

    func apply(
        _ state: BodyMapMetalRenderState,
        bundle: Bundle,
        animationsEnabled: Bool,
        transitionDuration: Double
    ) {
        let now = CACurrentMediaTime()
        let previous = presentationState(at: now) ?? targetState
        let bundleChanged = resourceBundlePath != bundle.bundlePath
        let masksChanged = bundleChanged
            || maskSet?.model != state.model
            || maskSet?.side != state.side

        resourceBundle = bundle
        resourceBundlePath = bundle.bundlePath

        if masksChanged {
            do {
                maskSet = try textureLoader.loadMaskSet(
                    model: state.model,
                    side: state.side,
                    bundle: bundle
                )
            } catch {
                preconditionFailure("Unable to load BodyMap anatomy masks: \(error)")
            }
            blurSet = nil
            blurConfiguration = nil
            transition = nil
        }

        targetState = state
        prepareBlurTexturesIfNeeded()

        if !masksChanged,
           animationsEnabled,
           transitionDuration > 0,
           let previous,
           previous != state,
           previous.assets.map(\.asset) == state.assets.map(\.asset) {
            transition = Transition(
                from: previous,
                to: state,
                startedAt: now,
                duration: transitionDuration
            )
            view?.preferredFramesPerSecond = 60
            view?.isPaused = false
        } else {
            transition = nil
            view?.isPaused = true
            view?.setNeedsDisplay()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        blurConfiguration = nil
        prepareBlurTexturesIfNeeded()
        if transition == nil {
            view.setNeedsDisplay()
        }
    }

    func draw(in view: MTKView) {
        prepareBlurTexturesIfNeeded()

        let now = CACurrentMediaTime()
        guard let state = presentationState(at: now) ?? targetState,
              let maskSet,
              let blurSet,
              let renderPass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = resources.commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPass
              ) else {
            return
        }

        var frame = BodyMapMetalFrameUniforms(
            baseColor: state.baseColor,
            metadata: SIMD4(Float(state.assets.count), 0, 0, 0)
        )
        let assets = state.assets.map {
            BodyMapMetalAssetUniforms(
                fillColor: $0.fillColor,
                glowColor: $0.glowColor,
                shadowColor: $0.shadowColor,
                values: SIMD4(
                    $0.fillOpacity,
                    $0.glowOpacity,
                    $0.shadowOpacity,
                    $0.selectionOpacity
                )
            )
        }

        encoder.setRenderPipelineState(resources.renderPipeline)
        encoder.setFragmentTexture(maskSet.masks, index: 0)
        encoder.setFragmentTexture(blurSet.glow, index: 1)
        encoder.setFragmentTexture(blurSet.shadow, index: 2)
        encoder.setFragmentTexture(blurSet.selection, index: 3)
        encoder.setFragmentBytes(
            &frame,
            length: MemoryLayout<BodyMapMetalFrameUniforms>.stride,
            index: 0
        )
        assets.withUnsafeBufferPointer { buffer in
            guard let address = buffer.baseAddress else { return }
            encoder.setFragmentBytes(
                address,
                length: buffer.count * MemoryLayout<BodyMapMetalAssetUniforms>.stride,
                index: 1
            )
        }
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()

        settleTransitionIfNeeded(at: now, view: view)
    }

    private func presentationState(at now: TimeInterval) -> BodyMapMetalRenderState? {
        guard let transition else { return targetState }
        let linear = Float(
            min(max((now - transition.startedAt) / transition.duration, 0), 1)
        )
        let eased = linear * linear * (3 - 2 * linear)
        return transition.to.interpolated(
            from: transition.from,
            progress: eased
        )
    }

    private func settleTransitionIfNeeded(at now: TimeInterval, view: MTKView) {
        guard let transition else { return }
        guard now - transition.startedAt >= transition.duration else { return }
        self.transition = nil
        view.isPaused = true
        view.setNeedsDisplay()
    }

    private func prepareBlurTexturesIfNeeded() {
        guard let view,
              let state = targetState,
              let maskSet,
              view.bounds.width > 0 else {
            return
        }

        let configuration = BlurConfiguration(
            model: state.model,
            side: state.side,
            bundlePath: resourceBundlePath,
            pointWidthBucket: Int((view.bounds.width * 100).rounded()),
            glowRadiusBucket: Int((state.glowRadius * 100).rounded()),
            shadowRadiusBucket: Int((state.shadowRadius * 100).rounded())
        )
        guard blurConfiguration != configuration else { return }

        let pixelsPerPoint = Float(maskSet.width) / Float(view.bounds.width)
        do {
            blurSet = try textureLoader.makeBlurTextures(
                from: maskSet.masks,
                glowRadius: state.glowRadius * pixelsPerPoint,
                shadowRadius: state.shadowRadius * pixelsPerPoint,
                selectionRadius: 3 * pixelsPerPoint
            )
            blurConfiguration = configuration
        } catch {
            preconditionFailure("Unable to prepare BodyMap blur masks: \(error)")
        }
    }
}

private struct Transition {
    let from: BodyMapMetalRenderState
    let to: BodyMapMetalRenderState
    let startedAt: TimeInterval
    let duration: TimeInterval
}

private struct BlurConfiguration: Equatable {
    let model: BodyMapModel
    let side: BodyMapAnatomySide
    let bundlePath: String
    let pointWidthBucket: Int
    let glowRadiusBucket: Int
    let shadowRadiusBucket: Int
}

private struct BodyMapMetalFrameUniforms {
    var baseColor: SIMD4<Float>
    var metadata: SIMD4<Float>
}

private struct BodyMapMetalAssetUniforms {
    var fillColor: SIMD4<Float>
    var glowColor: SIMD4<Float>
    var shadowColor: SIMD4<Float>
    var values: SIMD4<Float>
}
#endif
