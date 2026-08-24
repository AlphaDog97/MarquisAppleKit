import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct BodyMapSideView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.bodyMapRenderingMode) private var renderingMode

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
        switch renderingMode {
        case .automatic:
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
        case .staticExport:
            swiftUIVisualLayer
        }
        #else
        swiftUIVisualLayer
        #endif
    }

    private var swiftUIVisualLayer: some View {
        ZStack {
            anatomyImage(
                BodyMapAnatomyAssetResolver.baseShapeAssetName(
                    model: configuration.model,
                    side: side
                )
            )
            .foregroundStyle(appearance.inactiveColor)
            .opacity(BodyMapBaseAppearance.baseOpacity)

            glowLayer
                .blendMode(.screen)

            fillLayer

            innerGlowLayer
                .blendMode(.screen)
        }
    }

    private var glowLayer: some View {
        ZStack {
            if BodyMapBaseAppearance.glowEnabled {
                ForEach(assets) { asset in
                    if let style = appearance.style(for: asset.region),
                       style.glow.opacity > 0 {
                        outsideGlow(for: asset, style: style)
                    }
                }
            }
        }
    }

    private func outsideGlow(
        for asset: BodyMapAnatomyAsset,
        style: BodyMapRegionStyle
    ) -> some View {
        ZStack {
            anatomyImage(assetName(for: asset))
                .foregroundStyle(style.glow.color)
                .blur(
                    radius: style.glow.radius
                        * BodyMapGlowMetrics.spreadScale
                )

            anatomyImage(assetName(for: asset))
                .foregroundStyle(Color.black)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .opacity(glowOpacity(for: style))
    }

    private var innerGlowLayer: some View {
        ZStack {
            if BodyMapBaseAppearance.glowEnabled {
                ForEach(assets) { asset in
                    if let style = appearance.style(for: asset.region),
                       style.glow.opacity > 0 {
                        anatomyImage(assetName(for: asset))
                            .foregroundStyle(style.glow.color)
                            .opacity(
                                glowOpacity(for: style)
                                    * BodyMapGlowMetrics.innerOpacityScale
                            )
                    }
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
                } else {
                    anatomyImage(assetName(for: asset))
                        .foregroundStyle(appearance.inactiveRegionColor)
                }
            }
        }
    }

    @ViewBuilder
    private var interactionLayer: some View {
        if renderingMode == .automatic, let onRegionTap {
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

    @ViewBuilder
    private func anatomyImage(_ name: String) -> some View {
        #if canImport(UIKit)
        Image(uiImage: staticUIImage(named: name))
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
        #elseif canImport(AppKit)
        if let url = BodyMapResourceResolver().pdfURL(
            named: name,
            bundle: configuration.resources.bundle
        ), let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            Image(name, bundle: configuration.resources.bundle)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
        #else
        Image(name, bundle: configuration.resources.bundle)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
        #endif
    }

    #if canImport(UIKit)
    private func staticUIImage(named name: String) -> UIImage {
        do {
            return try BodyMapStaticImageLoader().load(
                named: name,
                bundle: configuration.resources.bundle
            )
        } catch {
            preconditionFailure(
                "Unable to load BodyMap static export asset \(name): \(error)"
            )
        }
    }
    #endif

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
        return min(
            max(
                style.glow.opacity
                    * reveal(for: style)
                    * energy
                    * BodyMapGlowMetrics.opacityScale,
                0
            ),
            1
        )
    }

    private func shadowOpacity(for style: BodyMapRegionStyle) -> Double {
        let energy = max(1, style.shadow.energy + configuration.shader.shadowEnergy)
        return min(max(style.shadow.opacity * reveal(for: style) * energy, 0), 1)
    }
}
