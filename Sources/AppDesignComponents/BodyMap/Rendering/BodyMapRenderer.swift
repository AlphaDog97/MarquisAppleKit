import SwiftUI

public struct BodyMapRenderer: View {
    private let model: BodyMapModel
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration

    public init(
        model: BodyMapModel,
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration
    ) {
        self.model = model
        self.appearance = appearance
        self.animation = animation
    }

    public var body: some View {
        ZStack {
            appearance.backgroundColor

            ForEach(appearance.regionStyles) { region in
                RoundedRectangle(cornerRadius: 12)
                    .fill(region.color.opacity(region.fillOpacity))
                    .overlay {
                        if region.glow.opacity > 0 {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(region.glow.color.opacity(region.glow.opacity))
                                .blur(radius: region.glow.radius)
                        }
                    }
                    .shadow(
                        color: region.shadow.color.opacity(region.shadow.opacity),
                        radius: region.shadow.radius
                    )
                    .opacity(animation.enabled ? region.revealFactor : 1)
                    .scaleEffect(region.isSelected ? 1.03 : 1)
                    .animation(
                        animation.enabled
                            ? .easeInOut(duration: animation.transitionDuration)
                            : nil,
                        value: region.isSelected
                    )
            }
        }
    }
}
