import SwiftUI

struct BodyMapSideView: View {
    @Environment(\.colorScheme) private var colorScheme

    let side: BodyMapAnatomySide
    let configuration: BodyMapConfiguration
    let appearance: BodyMapAppearance
    let animation: BodyMapAnimationConfiguration
    let onRegionTap: ((BodyMapRegionID) -> Void)?

    private var assets: [BodyMapAnatomyAsset] {
        BodyMapAnatomyAsset.allCases.filter { $0.side == side }
    }

    var body: some View {
        ZStack {
            visualLayer
            interactionLayer
        }
        .aspectRatio(309.014 / 800, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var visualLayer: some View {
        #if canImport(UIKit)
        BodyMapMetalSurface(
            state: BodyMapMetalRenderStateBuilder.make(
                side: side,
                configuration: configuration,
                appearance: appearance,
                colorScheme: colorScheme
            ),
            bundle: configuration.resources.bundle,
            animation: animation
        )
        .accessibilityHidden(true)
        #else
        ZStack {
            anatomyImage(
                BodyMapAnatomyAssetResolver.baseShapeAssetName(
                    model: configuration.model,
                    side: side
                )
            )
            .foregroundStyle(appearance.inactiveColor)
            .opacity(0.10)

            glowLayer
                .blendMode(.screen)

            fillLayer
        }
        #endif
    }

    private var glowLayer: some View {
        ZStack {
            ForEach(assets) { asset in
                if let style = appearance.style(for: asset.region),
                   style.glow.opacity > 0 {
                    anatomyImage(assetName(for: asset))
                        .foregroundStyle(style.glow.color)
                        .opacity(glowOpacity(for: style))
                        .blur(radius: style.glow.radius)
                }
            }
        }
    }

    private var fillLayer: some View {
        ZStack {
            ForEach(assets) { asset in
                if let style = appearance.style(for: asset.region) {
                    anatomyImage(assetName(for: asset))
                        .foregroundStyle(style.color)
                        .opacity(fillOpacity(for: style))
                        .shadow(
                            color: style.shadow.color.opacity(shadowOpacity(for: style)),
                            radius: style.shadow.radius
                        )
                        .shadow(
                            color: style.isSelected
                                ? Color.white.opacity(0.65 * reveal(for: style))
                                : .clear,
                            radius: 3
                        )
                }
            }
        }
    }

    @ViewBuilder
    private var interactionLayer: some View {
        if let onRegionTap {
            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                guard let region = BodyMapHitTester.region(
                                    at: value.location,
                                    in: proxy.size,
                                    side: side,
                                    model: configuration.model,
                                    bundle: configuration.resources.bundle
                                ) else { return }
                                onRegionTap(region)
                            }
                    )
            }
        }
    }

    private func assetName(for asset: BodyMapAnatomyAsset) -> String {
        BodyMapAnatomyAssetResolver.assetName(
            model: configuration.model,
            asset: asset
        )
    }

    private func anatomyImage(_ name: String) -> some View {
        Image(name, bundle: configuration.resources.bundle)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    private func reveal(for style: BodyMapRegionStyle) -> Double {
        min(max(style.revealFactor, 0), 1)
    }

    private func fillOpacity(for style: BodyMapRegionStyle) -> Double {
        min(
            max(
                style.fillOpacity
                    * reveal(for: style)
                    * configuration.shader.intensity,
                0
            ),
            1
        )
    }

    private func glowOpacity(for style: BodyMapRegionStyle) -> Double {
        let energy = max(1, style.glow.energy + configuration.shader.glowEnergy)
        return min(max(style.glow.opacity * reveal(for: style) * energy, 0), 1)
    }

    private func shadowOpacity(for style: BodyMapRegionStyle) -> Double {
        let energy = max(1, style.shadow.energy + configuration.shader.shadowEnergy)
        return min(max(style.shadow.opacity * reveal(for: style) * energy, 0), 1)
    }
}
