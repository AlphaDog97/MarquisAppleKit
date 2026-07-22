import SwiftUI

public struct CoachMarkTargetID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

public enum CoachMarkPlacement: Hashable, Sendable {
    case automatic
    case top
    case bottom
}

public struct CoachMarkStep: Identifiable {
    public let id: String
    public let targetID: CoachMarkTargetID
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey
    public let iconSystemName: String?
    public let preferredPlacement: CoachMarkPlacement
    public let accent: Color?
    public let spotlightPadding: CGFloat
    public let spotlightCornerRadius: CGFloat

    public init(
        id: String,
        targetID: CoachMarkTargetID,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        iconSystemName: String? = nil,
        preferredPlacement: CoachMarkPlacement = .automatic,
        accent: Color? = nil,
        spotlightPadding: CGFloat = 10,
        spotlightCornerRadius: CGFloat = 12
    ) {
        precondition(!id.isEmpty, "Coach mark step IDs cannot be empty")
        precondition(spotlightPadding >= 0, "Spotlight padding cannot be negative")
        precondition(spotlightCornerRadius >= 0, "Spotlight corner radius cannot be negative")

        self.id = id
        self.targetID = targetID
        self.title = title
        self.message = message
        self.iconSystemName = iconSystemName
        self.preferredPlacement = preferredPlacement
        self.accent = accent
        self.spotlightPadding = spotlightPadding
        self.spotlightCornerRadius = spotlightCornerRadius
    }
}

public struct CoachMarkFlow: Identifiable {
    public let id: String
    public let steps: [CoachMarkStep]

    public init(id: String, steps: [CoachMarkStep]) {
        precondition(!id.isEmpty, "Coach mark flow IDs cannot be empty")
        precondition(!steps.isEmpty, "Coach mark flows require at least one step")
        precondition(
            Set(steps.map(\.id)).count == steps.count,
            "Coach mark step IDs must be unique within a flow"
        )

        self.id = id
        self.steps = steps
    }
}

public struct CoachMarkLabels {
    public let skip: LocalizedStringKey
    public let next: LocalizedStringKey
    public let done: LocalizedStringKey

    public init(
        skip: LocalizedStringKey = "Skip",
        next: LocalizedStringKey = "Next",
        done: LocalizedStringKey = "Got it"
    ) {
        self.skip = skip
        self.next = next
        self.done = done
    }
}
