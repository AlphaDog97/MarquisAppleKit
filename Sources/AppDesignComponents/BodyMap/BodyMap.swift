import SwiftUI

public struct BodyMap: View {
    private let configuration: BodyMapConfiguration
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration
    private let onRegionTap: ((BodyMapRegionID) -> Void)?

    public init(
        configuration: BodyMapConfiguration = .init(),
        regions: [BodyMapRegionStyle],
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init(),
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.appearance = appearance.withRegions(regions)
        self.animation = animation
        self.onRegionTap = onRegionTap
    }

    public init(
        model: BodyMapModel,
        regions: [BodyMapRegionStyle],
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init(),
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.init(
            configuration: .init(model: model),
            regions: regions,
            appearance: appearance,
            animation: animation,
            onRegionTap: onRegionTap
        )
    }

    public init(
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration = .init(),
        onRegionTap: ((BodyMapRegionID) -> Void)? = nil
    ) {
        self.configuration = .init()
        self.appearance = appearance
        self.animation = animation
        self.onRegionTap = onRegionTap
    }

    public var body: some View {
        BodyMapRenderer(
            configuration: configuration,
            appearance: appearance,
            animation: animation,
            onRegionTap: onRegionTap
        )
    }
}
