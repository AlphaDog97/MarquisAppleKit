import SwiftUI

struct BodyMapRenderer: View {
    private let configuration: BodyMapConfiguration
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration
    private let onRegionTap: ((BodyMapRegionID) -> Void)?

    init(
        configuration: BodyMapConfiguration,
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration,
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.appearance = appearance
        self.animation = animation
        self.onRegionTap = onRegionTap
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(BodyMapAnatomySide.allCases, id: \.rawValue) { side in
                BodyMapSideView(
                    side: side,
                    configuration: configuration,
                    appearance: appearance,
                    animation: animation,
                    onRegionTap: onRegionTap
                )
            }
        }
        .background(BodyMapBaseAppearance.backgroundColor)
        .animation(
            animation.enabled
                ? .easeInOut(duration: animation.transitionDuration)
                : nil,
            value: animationValues
        )
    }

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
