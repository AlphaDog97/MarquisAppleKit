import SwiftUI

struct CoachMarkTargetPreferenceKey: PreferenceKey {
    static let defaultValue: [CoachMarkTargetID: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [CoachMarkTargetID: Anchor<CGRect>],
        nextValue: () -> [CoachMarkTargetID: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private struct CoachMarkTargetModifier: ViewModifier {
    let id: CoachMarkTargetID

    func body(content: Content) -> some View {
        content.anchorPreference(
            key: CoachMarkTargetPreferenceKey.self,
            value: .bounds
        ) { [id: $0] }
    }
}

public extension View {
    func coachMarkTarget(_ id: CoachMarkTargetID) -> some View {
        modifier(CoachMarkTargetModifier(id: id))
    }

    @ViewBuilder
    func coachMarkTarget(
        _ id: CoachMarkTargetID,
        when condition: Bool
    ) -> some View {
        if condition {
            coachMarkTarget(id)
        } else {
            self
        }
    }
}
