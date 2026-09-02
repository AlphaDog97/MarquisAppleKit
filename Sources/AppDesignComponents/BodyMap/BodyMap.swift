import SwiftUI

public struct BodyMap: View {
    private let configuration: BodyMapConfiguration
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration
    private let reveal: BodyMapRevealRequest?
    private let onRevealCompleted: ((UUID) -> Void)?
    private let onRegionTap: ((BodyMapRegionID) -> Void)?

    public init(
        configuration: BodyMapConfiguration = .init(),
        regions: [BodyMapRegionStyle],
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init(),
        revealID: UUID? = nil,
        revealIntensities: [BodyMapRegionID: Double] = [:],
        onRevealCompleted: ((UUID) -> Void)? = nil,
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.appearance = appearance.withRegions(regions)
        self.animation = animation
        self.reveal = revealID.map {
            BodyMapRevealRequest(
                id: $0,
                regionIntensities: revealIntensities
            )
        }
        self.onRevealCompleted = onRevealCompleted
        self.onRegionTap = onRegionTap
    }

    public init(
        model: BodyMapModel,
        regions: [BodyMapRegionStyle],
        morphology: BodyMapMorphology = .neutral,
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init(),
        revealID: UUID? = nil,
        revealIntensities: [BodyMapRegionID: Double] = [:],
        onRevealCompleted: ((UUID) -> Void)? = nil,
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.init(
            configuration: .init(
                model: model,
                morphology: morphology
            ),
            regions: regions,
            appearance: appearance,
            animation: animation,
            revealID: revealID,
            revealIntensities: revealIntensities,
            onRevealCompleted: onRevealCompleted,
            onRegionTap: onRegionTap
        )
    }

    public init(
        appearance: BodyMapAppearance,
        morphology: BodyMapMorphology = .neutral,
        animation: BodyMapAnimationConfiguration = .init(),
        revealID: UUID? = nil,
        revealIntensities: [BodyMapRegionID: Double] = [:],
        onRevealCompleted: ((UUID) -> Void)? = nil,
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.configuration = .init(morphology: morphology)
        self.appearance = appearance
        self.animation = animation
        self.reveal = revealID.map {
            BodyMapRevealRequest(
                id: $0,
                regionIntensities: revealIntensities
            )
        }
        self.onRevealCompleted = onRevealCompleted
        self.onRegionTap = onRegionTap
    }

    public var body: some View {
        BodyMapRenderer(
            configuration: configuration,
            appearance: appearance,
            animation: animation,
            reveal: reveal,
            onRevealCompleted: onRevealCompleted,
            onRegionTap: onRegionTap
        )
    }
}
