import AppCore
import AppDesignTokens
import SwiftUI

struct ActionPromptButton: View {
    @Environment(\.appTheme) private var theme

    let action: ActionPromptAction
    let accent: Color
    let dismiss: @MainActor () -> Void

    @ViewBuilder
    var body: some View {
        if action.role == .cancel {
            button.keyboardShortcut(.cancelAction)
        } else {
            button
        }
    }

    private var button: some View {
        Button {
            dismiss()
            feedback()
            action.perform()
        } label: {
            Text(action.title)
                .appTextStyle(.control)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, AppSpacing.medium)
                .background(
                    background,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                    .stroke(border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch action.role {
        case .primary:
            accent
        case .destructive:
            theme.destructive
        case .secondary, .cancel:
            theme.background
        }
    }

    private var border: Color {
        switch action.role {
        case .primary, .destructive:
            .clear
        case .secondary, .cancel:
            theme.border
        }
    }

    private var foreground: Color {
        switch action.role {
        case .primary, .destructive:
            theme.onPrimary
        case .secondary, .cancel:
            theme.textPrimary
        }
    }

    @MainActor
    private func feedback() {
        if action.role == .destructive {
            HapticFeedback.notification(.warning)
        } else {
            HapticFeedback.selection()
        }
    }
}
