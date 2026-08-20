import SwiftUI

public struct BodyMap: View {
    private let configuration: BodyMapConfiguration
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration

    public init(
        configuration: BodyMapConfiguration = .init(),
        regions: [BodyMapRegionStyle],
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init()
    ) {
        self.configuration = configuration
        self.appearance = appearance.withRegions(regions)
        self.animation = animation
    }

    public init(
        model: BodyMapModel,
        regions: [BodyMapRegionStyle],
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init()
    ) {
        self.init(
            configuration: .init(model: model),
            regions: regions,
            appearance: appearance,
            animation: animation
        )
    }

    public init(
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration = .init()
    ) {
        self.configuration = .init()
        self.appearance = appearance
        self.animation = animation
    }

    public var body: some View {
        BodyMapRenderer(
            configuration: configuration,
            appearance: appearance,
            animation: animation
        )
    }
}
