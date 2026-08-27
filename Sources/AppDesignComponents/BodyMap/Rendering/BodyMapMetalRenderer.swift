#if canImport(UIKit)
import Foundation
import MetalKit
import QuartzCore

@MainActor
final class BodyMapMetalRenderer: NSObject, @preconcurrency MTKViewDelegate {
    let device: MTLDevice

    private static let hiddenRevealProgress = BodyMapRevealProgress(
        fill: 0,
        glow: 0,
        shadow: 0,
        selection: 0
    )

    private let resources: BodyMapMetalResources
    private let textureLoader: BodyMapTextureLoader
    private let blurBuilder: BodyMapBlurTextureBuilder
    private weak var view: MTKView?

    private var targetState: BodyMapMetalRenderState?
    private var transition: Transition?
    private var pendingReveal: PendingReveal?
    private var armedReveal: ArmedReveal?
    private var activeReveal: ActiveReveal?
    private var lastCompletedRevealID: UUID?
    private var onFirstFrameRendered: (() -> Void)?
    private var onRevealCompleted: ((UUID) -> Void)?
    private var maskSet: BodyMapMaskTextureSet?
    private var blurSet: BodyMapBlurTextureSet?
    private var blurConfiguration: BlurConfiguration?
    private var resourceBundlePath = Bundle.main.bundlePath
    private var revealStartWorkItem: DispatchWorkItem?
    private var displayLink: CADisplayLink?
    private var hasScheduledFirstFrameCompletion = false
    private lazy var displayLinkTarget = BodyMapDisplayLinkTarget(renderer: self)
    private var assetUniforms: [BodyMapMetalAssetUniforms] = []

    override init() {
        let resources = BodyMapMetalResources.shared
        self.resources = resources
        self.device = resources.device
        self.textureLoader = BodyMapTextureLoader(resources: resources)
        self.blurBuilder = BodyMapBlurTextureBuilder(resources: resources)
        super.init()
    }

    deinit {
        revealStartWorkItem?.cancel()
        displayLink?.invalidate()
    }

    func attach(
        to view: MTKView,
        onFirstFrameRendered: (() -> Void)? = nil
    ) {
        self.view = view
        self.onFirstFrameRendered = onFirstFrameRendered
        view.delegate = self
    }

    func apply(
        _ state: BodyMapMetalRenderState,
        bundle: Bundle,
        animationsEnabled: Bool,
        transitionDuration: Double,
        reveal: BodyMapRevealRequest?,
        onRevealCompleted: ((UUID) -> Void)?
    ) {
        let now = CACurrentMediaTime()
        let previous = presentationState(at: now) ?? targetState
        let bundleChanged = resourceBundlePath != bundle.bundlePath
        let masksChanged = bundleChanged
            || maskSet?.model != state.model
            || maskSet?.side != state.side

        resourceBundlePath = bundle.bundlePath
        self.onRevealCompleted = onRevealCompleted

        if masksChanged {
            do {
                maskSet = try textureLoader.loadMaskSet(
                    model: state.model,
                    side: state.side,
                    bundle: bundle
                )
            } catch {
                preconditionFailure(
                    "Unable to load BodyMap anatomy masks: \(error)"
                )
            }
            blurSet = nil
            blurConfiguration = nil
            transition = nil
        }

        targetState = state
        prepareBlurTexturesIfNeeded()
        updateReveal(
            reveal,
            animationsEnabled: animationsEnabled
        )

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
        } else {
            transition = nil
        }

        updateDrawingMode(requestStableDraw: true)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        blurConfiguration = nil
        prepareBlurTexturesIfNeeded()
        if !shouldContinuouslyDraw() {
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

        startArmedRevealIfNeeded(at: now)

        var frame = BodyMapMetalFrameUniforms(
            baseColor: state.baseColor,
            metadata: SIMD4(
                Float(state.assets.count),
                Float(BodyMapGlowMetrics.innerOpacityScale),
                0,
                0
            )
        )
        prepareAssetUniforms(
            for: state,
            maskSet: maskSet,
            viewSize: view.bounds.size,
            at: now
        )

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
        assetUniforms.withUnsafeBufferPointer { buffer in
            guard let address = buffer.baseAddress else { return }
            encoder.setFragmentBytes(
                address,
                length: buffer.count
                    * MemoryLayout<BodyMapMetalAssetUniforms>.stride,
                index: 1
            )
        }
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        let pendingRevealID = pendingReveal?.request.id
        if let pendingRevealID {
            commandBuffer.addCompletedHandler { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.beginPendingRevealIfNeeded(id: pendingRevealID)
                }
            }
        }

        if !hasScheduledFirstFrameCompletion {
            hasScheduledFirstFrameCompletion = true
            commandBuffer.addCompletedHandler { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.notifyFirstFrameRendered()
                }
            }
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()

        let completedRevealID = settleAnimationStateIfNeeded(at: now)
        updateDrawingMode(requestStableDraw: false)

        if let completedRevealID {
            onRevealCompleted?(completedRevealID)
        }
    }

    fileprivate func displayLinkDidFire() {
        guard shouldContinuouslyDraw(),
              let view,
              view.window != nil else {
            return
        }
        view.draw()
    }

    private func notifyFirstFrameRendered() {
        onFirstFrameRendered?()
    }

    private func prepareAssetUniforms(
        for state: BodyMapMetalRenderState,
        maskSet: BodyMapMaskTextureSet,
        viewSize: CGSize,
        at now: TimeInterval
    ) {
        precondition(
            maskSet.assetBounds.count == state.assets.count,
            "BodyMap asset bounds must match render-state assets"
        )

        if assetUniforms.count != state.assets.count {
            assetUniforms = Array(
                repeating: BodyMapMetalAssetUniforms.zero,
                count: state.assets.count
            )
        }

        let boundsPadding = assetInfluencePadding(
            for: state,
            viewSize: viewSize
        )

        for index in state.assets.indices {
            let asset = state.assets[index]
            let revealProgress = revealProgress(
                for: asset.asset.region,
                at: now
            )
            assetUniforms[index] = BodyMapMetalAssetUniforms(
                fillColor: asset.fillColor,
                glowColor: asset.glowColor,
                shadowColor: asset.shadowColor,
                values: SIMD4(
                    asset.fillOpacity,
                    asset.glowOpacity,
                    asset.shadowOpacity,
                    asset.selectionOpacity
                ),
                reveal: SIMD4(
                    revealProgress.fill,
                    revealProgress.glow,
                    revealProgress.shadow,
                    revealProgress.selection
                ),
                bounds: expandedAssetBounds(
                    maskSet.assetBounds[index],
                    padding: boundsPadding
                )
            )
        }
    }

    private func assetInfluencePadding(
        for state: BodyMapMetalRenderState,
        viewSize: CGSize
    ) -> SIMD2<Float> {
        let glowRadius = state.glowRadius
            * Float(BodyMapGlowMetrics.spreadScale)
        let influenceRadius = max(
            max(glowRadius, state.shadowRadius),
            3
        ) + 4

        return SIMD2(
            min(influenceRadius / max(Float(viewSize.width), 1), 1),
            min(influenceRadius / max(Float(viewSize.height), 1), 1)
        )
    }

    private func expandedAssetBounds(
        _ bounds: SIMD4<Float>,
        padding: SIMD2<Float>
    ) -> SIMD4<Float> {
        SIMD4(
            max(bounds.x - padding.x, 0),
            max(bounds.y - padding.y, 0),
            min(bounds.z + padding.x, 1),
            min(bounds.w + padding.y, 1)
        )
    }

    private func updateReveal(
        _ request: BodyMapRevealRequest?,
        animationsEnabled: Bool
    ) {
        guard let request else {
            cancelScheduledRevealStart()
            pendingReveal = nil
            armedReveal = nil
            activeReveal = nil
            return
        }

        if var pending = pendingReveal,
           pending.request.id == request.id {
            pending.request = request
            pendingReveal = pending
            return
        }

        if var armed = armedReveal,
           armed.request.id == request.id {
            armed.request = request
            armedReveal = armed
            return
        }

        if var current = activeReveal,
           current.request.id == request.id {
            current.request = request
            activeReveal = current
            return
        }

        cancelScheduledRevealStart()
        pendingReveal = nil
        armedReveal = nil
        activeReveal = nil

        guard lastCompletedRevealID != request.id else { return }

        let duration = animationsEnabled && !request.regionIntensities.isEmpty
            ? BodyMapRevealTimeline.totalDuration
            : 0

        guard duration > 0 else {
            activeReveal = ActiveReveal(
                request: request,
                startedAt: CACurrentMediaTime(),
                duration: 0
            )
            return
        }

        pendingReveal = PendingReveal(
            request: request,
            duration: duration
        )
    }

    private func beginPendingRevealIfNeeded(id: UUID) {
        guard let pendingReveal,
              pendingReveal.request.id == id else {
            return
        }

        self.pendingReveal = nil
        armedReveal = ArmedReveal(
            request: pendingReveal.request,
            duration: pendingReveal.duration,
            isReadyToStart: false
        )

        let delay = BodyMapRevealTimeline.presentationDelay
        if delay > 0 {
            scheduleRevealStart(id: id, delay: delay)
        } else {
            markArmedRevealReadyIfNeeded(id: id)
        }
    }

    private func scheduleRevealStart(id: UUID, delay: TimeInterval) {
        guard delay > 0 else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.revealStartWorkItem = nil
            self.markArmedRevealReadyIfNeeded(id: id)
        }
        revealStartWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay,
            execute: workItem
        )
    }

    private func markArmedRevealReadyIfNeeded(id: UUID) {
        guard var armedReveal,
              armedReveal.request.id == id else {
            return
        }

        armedReveal.isReadyToStart = true
        self.armedReveal = armedReveal
        updateDrawingMode(requestStableDraw: true)
    }

    private func startArmedRevealIfNeeded(at now: TimeInterval) {
        guard let armedReveal,
              armedReveal.isReadyToStart else {
            return
        }

        self.armedReveal = nil
        activeReveal = ActiveReveal(
            request: armedReveal.request,
            startedAt: now,
            duration: armedReveal.duration
        )
    }

    private func cancelScheduledRevealStart() {
        revealStartWorkItem?.cancel()
        revealStartWorkItem = nil
    }

    private func revealProgress(
        for region: BodyMapRegionID,
        at now: TimeInterval
    ) -> BodyMapRevealProgress {
        if let pendingReveal {
            guard pendingReveal.request.regionIntensities[region] != nil else {
                return .complete
            }
            return Self.hiddenRevealProgress
        }

        if let armedReveal {
            guard armedReveal.request.regionIntensities[region] != nil else {
                return .complete
            }
            return Self.hiddenRevealProgress
        }

        guard let activeReveal else { return .complete }
        guard activeReveal.duration > 0 else { return .complete }

        return BodyMapRevealTimeline.progress(
            for: region,
            request: activeReveal.request,
            elapsed: activeRevealElapsed(activeReveal, at: now)
        )
    }

    private func activeRevealElapsed(
        _ activeReveal: ActiveReveal,
        at now: TimeInterval
    ) -> TimeInterval {
        BodyMapRevealTimeline.presentationDelay
            + max(now - activeReveal.startedAt, 0)
    }

    private func presentationState(
        at now: TimeInterval
    ) -> BodyMapMetalRenderState? {
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

    private func settleAnimationStateIfNeeded(
        at now: TimeInterval
    ) -> UUID? {
        if let transition,
           now - transition.startedAt >= transition.duration {
            self.transition = nil
        }

        guard let activeReveal,
              activeRevealElapsed(activeReveal, at: now)
                >= activeReveal.duration else {
            return nil
        }

        self.activeReveal = nil
        cancelScheduledRevealStart()
        lastCompletedRevealID = activeReveal.request.id
        return activeReveal.request.id
    }

    private func shouldContinuouslyDraw() -> Bool {
        if transition != nil {
            return true
        }

        if armedReveal?.isReadyToStart == true {
            return true
        }

        return (activeReveal?.duration ?? 0) > 0
    }

    private func updateDrawingMode(requestStableDraw: Bool) {
        guard let view else { return }

        let shouldDrawContinuously = shouldContinuouslyDraw()
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        setDisplayLinkActive(shouldDrawContinuously)

        if !shouldDrawContinuously, requestStableDraw {
            view.setNeedsDisplay()
        }
    }

    private func setDisplayLinkActive(_ isActive: Bool) {
        if isActive {
            guard displayLink == nil else { return }

            let link = CADisplayLink(
                target: displayLinkTarget,
                selector: #selector(BodyMapDisplayLinkTarget.tick(_:))
            )
            link.preferredFramesPerSecond = 60
            link.add(to: .main, forMode: .common)
            displayLink = link
            return
        }

        displayLink?.invalidate()
        displayLink = nil
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
            blurSet = try blurBuilder.makeTextures(
                from: maskSet.masks,
                glowRadius: state.glowRadius * pixelsPerPoint,
                shadowRadius: state.shadowRadius * pixelsPerPoint,
                selectionRadius: 3 * pixelsPerPoint
            )
            blurConfiguration = configuration
        } catch {
            preconditionFailure(
                "Unable to prepare BodyMap blur masks: \(error)"
            )
        }
    }
}

@MainActor
private final class BodyMapDisplayLinkTarget: NSObject {
    weak var renderer: BodyMapMetalRenderer?

    init(renderer: BodyMapMetalRenderer) {
        self.renderer = renderer
    }

    @objc func tick(_ displayLink: CADisplayLink) {
        renderer?.displayLinkDidFire()
    }
}

private struct Transition {
    let from: BodyMapMetalRenderState
    let to: BodyMapMetalRenderState
    let startedAt: TimeInterval
    let duration: TimeInterval
}

private struct PendingReveal {
    var request: BodyMapRevealRequest
    let duration: TimeInterval
}

private struct ArmedReveal {
    var request: BodyMapRevealRequest
    let duration: TimeInterval
    var isReadyToStart: Bool
}

private struct ActiveReveal {
    var request: BodyMapRevealRequest
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
    var reveal: SIMD4<Float>
    var bounds: SIMD4<Float>

    static let zero = BodyMapMetalAssetUniforms(
        fillColor: .zero,
        glowColor: .zero,
        shadowColor: .zero,
        values: .zero,
        reveal: .zero,
        bounds: .zero
    )
}
#endif