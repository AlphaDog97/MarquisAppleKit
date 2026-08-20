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
            renderBackground(in: &context, size: size)
            renderRegions(in: &context, size: size)
        }
        .animation(
            animation.enabled
                ? .easeInOut(duration: animation.transitionDuration)
                : nil,
            value: appearance.regionStyles.map(\.id)
        )
    }

    private func renderBackground(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(appearance.backgroundColor)
        )
    }

    private func renderRegions(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let regionCount = max(appearance.regionStyles.count, 1)
        let regionHeight = size.height / CGFloat(regionCount)

        for (index, region) in appearance.regionStyles.enumerated() {
            let frame = CGRect(
                x: 0,
                y: CGFloat(index) * regionHeight,
                width: size.width,
                height: regionHeight
            )

            drawRegion(
                region,
                frame: frame,
                in: &context
            )
        }
    }

    private func drawRegion(
        _ region: BodyMapRegionStyle,
        frame: CGRect,
        in context: inout GraphicsContext
    ) {
        var path = Path()
        path.addRoundedRect(
            in: frame,
            cornerSize: CGSize(width: 12, height: 12)
        )

        context.fill(
            path,
            with: .color(region.color.opacity(region.fillOpacity))
        )

        if region.glow.opacity > 0 {
            context.stroke(
                path,
                with: .color(region.glow.color.opacity(region.glow.opacity)),
                lineWidth: region.glow.radius
            )
        }
    }
}
