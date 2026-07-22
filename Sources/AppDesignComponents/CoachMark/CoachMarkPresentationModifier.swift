import AppDesignTokens
import SwiftUI

private struct CoachMarkPresentationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var currentStepIndex: Int?

    let flow: CoachMarkFlow?
    let labels: CoachMarkLabels
    let onSkip: @MainActor () -> Void
    let onCompletion: @MainActor () -> Void

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(CoachMarkTargetPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    if let context = presentationContext(
                        anchors: anchors,
                        proxy: proxy
                    ) {
                        CoachMarkOverlay(
                            step: context.step,
                            isLastStep: context.index == context.stepCount - 1,
                            labels: labels,
                            targetRect: context.targetRect,
                            containerSize: proxy.size,
                            safeAreaInsets: proxy.safeAreaInsets,
                            onSkip: skip,
                            onAdvance: advance
                        )
                        .zIndex(20_000)
                    }
                }
                .ignoresSafeArea()
            }
            .animation(
                reduceMotion
                    ? .easeInOut(duration: 0.15)
                    : .spring(response: 0.32, dampingFraction: 0.86),
                value: currentStepIndex
            )
    }

    private func presentationContext(
        anchors: [CoachMarkTargetID: Anchor<CGRect>],
        proxy: GeometryProxy
    ) -> PresentationContext? {
        guard
            let flow,
            let index = currentStepIndex,
            flow.steps.indices.contains(index)
        else {
            return nil
        }

        let step = flow.steps[index]
        guard let anchor = anchors[step.targetID] else {
            return nil
        }

        return PresentationContext(
            step: step,
            index: index,
            stepCount: flow.steps.count,
            targetRect: proxy[anchor]
        )
    }

    @MainActor
    private func skip() {
        currentStepIndex = nil
        onSkip()
    }

    @MainActor
    private func advance() {
        guard
            let flow,
            let index = currentStepIndex,
            flow.steps.indices.contains(index)
        else {
            currentStepIndex = nil
            return
        }

        let nextIndex = index + 1
        if flow.steps.indices.contains(nextIndex) {
            currentStepIndex = nextIndex
        } else {
            currentStepIndex = nil
            onCompletion()
        }
    }
}

private struct PresentationContext {
    let step: CoachMarkStep
    let index: Int
    let stepCount: Int
    let targetRect: CGRect
}

public extension View {
    func coachMarkFlow(
        _ flow: CoachMarkFlow?,
        currentStepIndex: Binding<Int?>,
        labels: CoachMarkLabels = CoachMarkLabels(),
        onSkip: @escaping @MainActor () -> Void = {},
        onCompletion: @escaping @MainActor () -> Void = {}
    ) -> some View {
        modifier(
            CoachMarkPresentationModifier(
                currentStepIndex: currentStepIndex,
                flow: flow,
                labels: labels,
                onSkip: onSkip,
                onCompletion: onCompletion
            )
        )
    }
}
