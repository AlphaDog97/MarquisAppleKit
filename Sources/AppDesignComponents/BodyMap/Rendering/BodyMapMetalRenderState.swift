#if canImport(UIKit)
import SwiftUI
import UIKit

struct BodyMapMetalRenderState: Equatable {
    let model: BodyMapModel
    let side: BodyMapAnatomySide
    let morphology: BodyMapMorphology
    let baseColor: SIMD4<Float>
    let assets: [Asset]
    let glowRadius: Float
    let shadowRadius: Float

    struct Asset: Equatable {
        let asset: BodyMapAnatomyAsset
        let fillColor: SIMD4<Float>
        let glowColor: SIMD4<Float>
        let shadowColor: SIMD4<Float>
        let fillOpacity: Float
        let glowOpacity: Float
        let shadowOpacity: Float
        let selectionOpacity: Float
    }

    func interpolated(from start: Self, progress: Float) -> Self {
        guard start.model == model,
              start.side == side,
              start.assets.map(\.asset) == assets.map(\.asset) else {
            return self
        }

        let t = min(max(progress, 0), 1)
        return Self(
            model: model,
            side: side,
            morphology: morphology.interpolated(
                from: start.morphology,
                progress: t
            ),
            baseColor: mix(start.baseColor, baseColor, t),
            assets: zip(start.assets, assets).map { source, target in
                Asset(
                    asset: target.asset,
                    fillColor: mix(source.fillColor, target.fillColor, t),
                    glowColor: mix(source.glowColor, target.glowColor, t),
                    shadowColor: mix(source.shadowColor, target.shadowColor, t),
                    fillOpacity: mix(source.fillOpacity, target.fillOpacity, t),
                    glowOpacity: mix(source.glowOpacity, target.glowOpacity, t),
                    shadowOpacity: mix(source.shadowOpacity, target.shadowOpacity, t),
                    selectionOpacity: mix(source.selectionOpacity, target.selectionOpacity, t)
                )
            },
            glowRadius: mix(start.glowRadius, glowRadius, t),
            shadowRadius: shadowRadius
        )
    }

    private func mix(_ source: SIMD4<Float>, _ target: SIMD4<Float>, _ t: Float) -> SIMD4<Float> {
        source + (target - source) * t
    }

    private func mix(_ source: Float, _ target: Float, _ t: Float) -> Float {
        source + (target - source) * t
    }
}

@MainActor
enum BodyMapMetalRenderStateBuilder {
    static func make(
        side: BodyMapAnatomySide,
        configuration: BodyMapConfiguration,
        appearance: BodyMapAppearance,
        colorScheme: ColorScheme
    ) -> BodyMapMetalRenderState {
        let assets = BodyMapAnatomyAsset.allCases.filter { $0.side == side }
        let styles = appearance.regionStyles
        let glowEnabled = BodyMapBaseAppearance.glowEnabled

        return BodyMapMetalRenderState(
            model: configuration.model,
            side: side,
            morphology: configuration.morphology,
            baseColor: rgba(
                appearance.inactiveColor,
                colorScheme: colorScheme,
                alphaMultiplier: BodyMapBaseAppearance.baseOpacity
            ),
            assets: assets.map { asset in
                let style = styles.first { $0.id == asset.region }
                return renderAsset(
                    asset,
                    style: style,
                    inactiveColor: appearance.inactiveRegionColor,
                    glowEnabled: appearance.glowEnabled,
                    configuration: configuration,
                    colorScheme: colorScheme
                )
            },
            glowRadius: glowEnabled
                ? Float(styles.map(\.glow.radius).max() ?? 0)
                : 0,
            shadowRadius: Float(styles.map(\.shadow.radius).max() ?? 0)
        )
    }

    private static func renderAsset(
        _ asset: BodyMapAnatomyAsset,
        style: BodyMapRegionStyle?,
        inactiveColor: Color,
        glowEnabled: Bool,
        configuration: BodyMapConfiguration,
        colorScheme: ColorScheme
    ) -> BodyMapMetalRenderState.Asset {
        guard let style else {
            return .init(
                asset: asset,
                fillColor: rgba(inactiveColor, colorScheme: colorScheme),
                glowColor: .zero,
                shadowColor: .zero,
                fillOpacity: 1,
                glowOpacity: 0,
                shadowOpacity: 0,
                selectionOpacity: 0
            )
        }

        let reveal = clamp(style.revealFactor)
        let fill = clamp(style.fillOpacity * reveal * configuration.shader.intensity)
        let glowEnergy = max(1, style.glow.energy + configuration.shader.glowEnergy)
        let shadowEnergy = max(1, style.shadow.energy + configuration.shader.shadowEnergy)
        let glowOpacity = clamp(
            style.glow.opacity
                * reveal
                * glowEnergy
                * BodyMapGlowMetrics.opacityScale
        )

        return .init(
            asset: asset,
            fillColor: rgba(style.color, colorScheme: colorScheme),
            glowColor: rgba(style.glow.color, colorScheme: colorScheme),
            shadowColor: rgba(style.shadow.color, colorScheme: colorScheme),
            fillOpacity: Float(fill),
            glowOpacity: glowEnabled ? Float(glowOpacity) : 0,
            shadowOpacity: Float(clamp(style.shadow.opacity * reveal * shadowEnergy)),
            selectionOpacity: style.isSelected ? Float(reveal) : 0
        )
    }

    private static func rgba(
        _ color: Color,
        colorScheme: ColorScheme,
        alphaMultiplier: Double = 1
    ) -> SIMD4<Float> {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return .zero
        }

        return SIMD4(Float(red), Float(green), Float(blue), Float(alpha * alphaMultiplier))
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
#endif
