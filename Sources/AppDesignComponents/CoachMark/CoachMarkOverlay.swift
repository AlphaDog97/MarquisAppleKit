import AppDesignTokens
import SwiftUI

struct CoachMarkOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var calloutContentHeight: CGFloat = 160

    let step: CoachMarkStep
    let isLastStep: Bool
    let labels: CoachMarkLabels
    let targetRect: CGRect
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets
    let onSkip: @MainActor () -> Void
    let onAdvance: @MainActor () -> Void

    private let cardWidth: CGFloat = 340

    var body: some View {
        ZStack(alignment: .topLeading) {
            spotlightLayer

            CoachMarkCalloutCard(
                step: step,
                isLastStep: isLastStep,
                labels: labels,
                maxHeight: calloutMaxHeight,
                contentHeight: $calloutContentHeight,
                onSkip: onSkip,
                onAdvance: onAdvance
            )
            .frame(width: resolvedCardWidth)
            .position(cardPosition)
            .transition(
                reduceMotion
                    ? .opacity
                    : .opacity.combined(with: .scale(scale: 0.96))
            )
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .accessibilityAddTraits(.isModal)
    }

    private var spotlightLayer: some View {
        CoachMarkSpotlightShape(
            rect: spotlightRect,
            cornerRadius: step.spotlightCornerRadius
        )
        .fill(
            Color.black.opacity(colorScheme == .dark ? 0.50 : 0.56),
            style: FillStyle(eoFill: true)
        )
        .contentShape(Rectangle())
        .onTapGesture { }
        .accessibilityHidden(true)
    }

    private var spotlightRect: CGRect {
        targetRect.insetBy(
            dx: -step.spotlightPadding,
            dy: -step.spotlightPadding
        )
    }

    private var resolvedCardWidth: CGFloat {
        min(cardWidth, max(0, containerSize.width - AppSpacing.large * 2))
    }

    private var cardPosition: CGPoint {
        let halfWidth = resolvedCardWidth / 2
        let horizontalMargin = AppSpacing.medium
        let x = min(
            max(
                targetRect.midX,
                safeAreaInsets.leading + halfWidth + horizontalMargin
            ),
            containerSize.width
                - safeAreaInsets.trailing
                - halfWidth
                - horizontalMargin
        )

        let halfHeight = displayedCalloutHeight / 2
        let verticalMargin = AppSpacing.medium
        let proposedY: CGFloat

        switch resolvedPlacement {
        case .top:
            proposedY = targetRect.minY - halfHeight - verticalMargin
        case .bottom, .automatic:
            proposedY = targetRect.maxY + halfHeight + verticalMargin
        }

        let minY = safeAreaInsets.top + halfHeight + verticalMargin
        let maxY = containerSize.height
            - safeAreaInsets.bottom
            - halfHeight
            - verticalMargin

        return CGPoint(x: x, y: min(max(proposedY, minY), maxY))
    }

    private var resolvedPlacement: CoachMarkPlacement {
        guard step.preferredPlacement == .automatic else {
            return step.preferredPlacement
        }

        let spaceAbove = targetRect.minY - safeAreaInsets.top
        let spaceBelow = containerSize.height
            - safeAreaInsets.bottom
            - targetRect.maxY

        return spaceBelow >= spaceAbove ? .bottom : .top
    }

    private var calloutMaxHeight: CGFloat {
        min(
            360,
            max(
                0,
                containerSize.height
                    - safeAreaInsets.top
                    - safeAreaInsets.bottom
                    - AppSpacing.large * 2
            )
        )
    }

    private var displayedCalloutHeight: CGFloat {
        min(calloutContentHeight, calloutMaxHeight)
    }
}

private struct CoachMarkSpotlightShape: Shape {
    let rect: CGRect
    let cornerRadius: CGFloat

    func path(in bounds: CGRect) -> Path {
        var path = Path(bounds)
        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return path
    }
}
