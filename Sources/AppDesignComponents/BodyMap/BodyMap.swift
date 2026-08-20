import SwiftUI

public struct BodyMap: View {
    private let model: BodyMapModel
    private let appearance: BodyMapAppearance
    private let animation: BodyMapAnimationConfiguration

    public init(
        model: BodyMapModel,
        regions: [BodyMapRegionStyle],
        appearance: BodyMapAppearance = .init(),
        animation: BodyMapAnimationConfiguration = .init()
    ) {
        self.model = model
        self.appearance = appearance.withRegions(regions)
        self.animation = animation
    }

    public init(
        appearance: BodyMapAppearance,
        animation: BodyMapAnimationConfiguration = .init()
    ) {
        self.model = .male
        self.appearance = appearance
        self.animation = animation
    }

    public var body: some View {
        BodyMapRenderer(
            model: model,
            appearance: appearance,
            animation: animation
        )
    }
}
