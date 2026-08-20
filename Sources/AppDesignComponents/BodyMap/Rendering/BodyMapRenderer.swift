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
        Canvas { context, size in
            renderBackground(
                context: &context,
                size: size
            )

            renderRegions(
                context: &context,
                size: size
            )
        }
        .animation(
            animation.enabled
                ? .easeInOut(duration: animation.transitionDuration)
                : nil,
            value: appearance.regionStyles.map(\.id)
        )
    }

    private func renderBackground(
        context: inout GraphicsContext,
        size: CGSize
    ) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(appearance.backgroundColor)
        )
    }

    private func renderRegions(
        context: inout GraphicsContext,
        size: CGSize
    ) {
        let regionSize = CGSize(
            width: size.width * 0.18,
            height: size.height * 0.08
        )

        for (index, region) in appearance.regionStyles.enumerated() {
            let origin = CGPoint(
                x: size.width * 0.41,
                y: CGFloat(index) * regionSize.height * 1.3
            )

            let rect = CGRect(
                origin: origin,
                size: regionSize
            )

            drawRegion(
                context: &context,
                region: region,
                rect: rect
            )
        }
    }

    private func drawRegion(
        context: inout GraphicsContext,
        region: BodyMapRegionStyle,
        rect: CGRect
    ) {
        let path = Path(
            roundedRect: rect,
            cornerRadius: 12
        )

        context.fill(
            path,
            with: .color(region.color.opacity(region.fillOpacity))
        )

        if region.glow.opacity > 0 {
            context.addFilter(
                .blur(radius: region.glow.radius)
            )

            context.stroke(
                path,
                with: .color(region.glow.color.opacity(region.glow.opacity))
            )
        }
    }
}
