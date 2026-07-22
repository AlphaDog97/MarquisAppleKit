import SwiftUI

public enum ActionPromptStyle: Hashable, Sendable {
    case destructive
    case warning
    case info
    case completion
    case replacement

    public var defaultIconSystemName: String {
        switch self {
        case .destructive, .warning:
            "exclamationmark.triangle.fill"
        case .info:
            "info.circle.fill"
        case .completion:
            "checkmark.circle.fill"
        case .replacement:
            "arrow.triangle.2.circlepath.circle.fill"
        }
    }
}

public struct ActionPromptAction: Identifiable {
    public enum Role: Hashable, Sendable {
        case primary
        case secondary
        case destructive
        case cancel
    }

    public let id: UUID
    public let title: LocalizedStringKey
    public let role: Role

    private let handler: @MainActor () -> Void

    public init(
        id: UUID = UUID(),
        _ title: LocalizedStringKey,
        role: Role,
        action: @escaping @MainActor () -> Void = {}
    ) {
        self.id = id
        self.title = title
        self.role = role
        handler = action
    }

    @MainActor
    public func perform() {
        handler()
    }
}

public struct ActionPromptState: Identifiable {
    public let id: UUID
    public let style: ActionPromptStyle
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey?
    public let detail: LocalizedStringKey?
    public let iconSystemName: String?
    public let accent: Color?
    public let actions: [ActionPromptAction]
    public let dismissOnBackdropTap: Bool

    public init(
        id: UUID = UUID(),
        style: ActionPromptStyle,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        detail: LocalizedStringKey? = nil,
        iconSystemName: String? = nil,
        accent: Color? = nil,
        actions: [ActionPromptAction],
        dismissOnBackdropTap: Bool = false
    ) {
        precondition(
            (1...3).contains(actions.count),
            "Action prompts require one to three actions"
        )
        precondition(
            actions.filter { $0.role == .cancel }.count <= 1,
            "Action prompts support at most one cancel action"
        )

        self.id = id
        self.style = style
        self.title = title
        self.message = message
        self.detail = detail
        self.iconSystemName = iconSystemName
        self.accent = accent
        self.actions = actions
        self.dismissOnBackdropTap = dismissOnBackdropTap
    }
}
