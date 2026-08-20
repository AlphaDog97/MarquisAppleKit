import SwiftUI

public struct BodyMap: View {
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration

    public init(
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration = .init()
    ) {
        self.appearance = appearance
        self.animation = animation
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                appearance.backgroundColor

                ForEach(appearance.regionStyles) { style in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(style.color.opacity(style.fillOpacity))
                        .shadow(
                            color: style.color.opacity(style.shadow.opacity),
                            radius: style.shadow.radius
                        )
                        .blur(radius: style.glow.radius)
                        .opacity(animation.enabled ? style.animationFactor : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(
                animation.enabled ? .easeInOut(duration: animation.transitionDuration) : nil,
                value: appearance.regionStyles.map(\.id)
            )
        }
    }
}
