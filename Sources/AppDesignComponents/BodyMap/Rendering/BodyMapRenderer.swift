import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct BodyMapRenderer: View {
    @Environment(\.bodyMapRenderingMode) private var renderingMode

    private let configuration: BodyMapConfiguration
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration
    private let reveal: BodyMapRevealRequest?
    private let onRevealCompleted: ((UUID) -> Void)?
    private let onRegionTap: ((BodyMapRegionID) -> Void)?

#if canImport(UIKit)
    @State private var revealCompletion = BodyMapRevealCompletionState()
    @State private var preparedSides: Set<String> = []
    @State private var presentedSides: Set<String> = []
    @State private var preparedPreparationID: String?
#endif

    init(
        configuration: BodyMapConfiguration,
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration,
        reveal: BodyMapRevealRequest? = nil,
        onRevealCompleted: ((UUID) -> Void)? = nil,
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.appearance = appearance
        self.animation = animation
        self.reveal = reveal
        self.onRevealCompleted = onRevealCompleted
        self.onRegionTap = onRegionTap
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(BodyMapAnatomySide.allCases, id: \.rawValue) { side in
                renderedSide(side)
            }
        }
        .background(appearance.backgroundColor)
#if canImport(UIKit)
        .task(id: preparationTaskID(for: .front)) {
            guard renderingMode == .automatic else { return }
            await prepare(.front, for: preparationID)
        }
        .task(id: preparationTaskID(for: .back)) {
            guard renderingMode == .automatic else { return }
            await prepare(.back, for: preparationID)
        }
#endif
        .animation(
            animation.enabled
                ? .easeInOut(duration: animation.transitionDuration)
                : nil,
            value: animationValues
        )
    }

    @ViewBuilder
    private func renderedSide(_ side: BodyMapAnatomySide) -> some View {
#if canImport(UIKit)
        if renderingMode == .automatic {
            stagedSide(side)
        } else {
            standardSide(side)
        }
#else
        standardSide(side)
#endif
    }

    private func standardSide(_ side: BodyMapAnatomySide) -> some View {
        BodyMapSideView(
            side: side,
            configuration: configuration,
            appearance: appearance,
            animation: animation,
            reveal: nil,
            onFirstFrameRendered: nil,
            onRevealCompleted: nil,
            onRegionTap: onRegionTap
        )
    }

#if canImport(UIKit)
    private var preparationID: String {
        let model = configuration.model == .male ? "male" : "female"
        return "\(configuration.resources.bundle.bundlePath)|\(model)"
    }

    private func preparationTaskID(for side: BodyMapAnatomySide) -> String {
        "\(preparationID)|\(side.rawValue)|\(renderingMode == .automatic)"
    }

    @ViewBuilder
    private func stagedSide(_ side: BodyMapAnatomySide) -> some View {
        if preparedPreparationID == preparationID,
           preparedSides.contains(side.rawValue) {
            ZStack {
                BodyMapSidePlaceholder(
                    side: side,
                    configuration: configuration,
                    appearance: appearance
                )
                .opacity(presentedSides.contains(side.rawValue) ? 0 : 1)

                BodyMapSideView(
                    side: side,
                    configuration: configuration,
                    appearance: appearance,
                    animation: animation,
                    reveal: reveal,
                    onFirstFrameRendered: {
                        presentMetalSurface(side)
                    },
                    onRevealCompleted: { id in
                        recordRevealCompletion(id: id, side: side)
                    },
                    onRegionTap: onRegionTap
                )
                .opacity(presentedSides.contains(side.rawValue) ? 1 : 0)
            }
        } else {
            BodyMapSidePlaceholder(
                side: side,
                configuration: configuration,
                appearance: appearance
            )
        }
    }

    @MainActor
    private func prepare(
        _ side: BodyMapAnatomySide,
        for id: String
    ) async {
        beginPreparationIfNeeded(for: id)

        do {
            try await BodyMapMaskPrewarmer.prewarm(
                model: configuration.model,
                side: side,
                bundle: configuration.resources.bundle
            )
            guard !Task.isCancelled, id == preparationID else { return }
            preparedSides.insert(side.rawValue)
        } catch {
            preconditionFailure(
                "Unable to prewarm BodyMap \(side.rawValue) masks: \(error)"
            )
        }
    }

    @MainActor
    private func beginPreparationIfNeeded(for id: String) {
        guard preparedPreparationID != id else { return }
        preparedPreparationID = id
        preparedSides = []
        presentedSides = []
        revealCompletion = BodyMapRevealCompletionState()
    }

    @MainActor
    private func presentMetalSurface(_ side: BodyMapAnatomySide) {
        guard !presentedSides.contains(side.rawValue) else { return }
        withAnimation(.smooth(duration: 0.20, extraBounce: 0)) {
            presentedSides.insert(side.rawValue)
        }
    }

    private func recordRevealCompletion(
        id: UUID,
        side: BodyMapAnatomySide
    ) {
        guard reveal?.id == id else { return }

        var state = revealCompletion
        if state.id != id {
            state = BodyMapRevealCompletionState(id: id)
        }
        guard !state.notified else { return }

        state.completedSides.insert(side.rawValue)
        if state.completedSides.count == BodyMapAnatomySide.allCases.count {
            state.notified = true
        }
        revealCompletion = state

        if state.notified {
            onRevealCompleted?(id)
        }
    }
#endif

    private var animationValues: [Double] {
        appearance.regionStyles.flatMap { style in
            [
                style.fillOpacity,
                style.glow.opacity,
                style.shadow.opacity,
                style.revealFactor,
                style.isSelected ? 1 : 0
            ]
        }
    }
}

#if canImport(UIKit)
private struct BodyMapSidePlaceholder: View {
    let side: BodyMapAnatomySide
    let configuration: BodyMapConfiguration
    let appearance: BodyMapAppearance

    var body: some View {
        Image(uiImage: image)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(appearance.inactiveColor)
            .bodyMapMorphologyEffect(configuration.morphology)
            .accessibilityHidden(true)
            .aspectRatio(309.014 / 800, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var image: UIImage {
        let name = BodyMapAnatomyAssetResolver.baseShapeAssetName(
            model: configuration.model,
            side: side
        )
        do {
            return try BodyMapStaticImageLoader().load(
                named: name,
                bundle: configuration.resources.bundle
            )
        } catch {
            preconditionFailure(
                "Unable to load BodyMap placeholder asset \(name): \(error)"
            )
        }
    }
}

private struct BodyMapRevealCompletionState {
    var id: UUID?
    var completedSides: Set<String> = []
    var notified = false
}
#endif
