import AppDesignTokens
import SwiftUI

struct ActionPromptCard: View {
    @Environment(\.appTheme) private var theme
    @State private var contentHeight: CGFloat = 320

    let prompt: ActionPromptState
    let maxHeight: CGFloat
    let titleIsFocused: AccessibilityFocusState<Bool>.Binding
    let dismiss: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                icon
                copy
                actionList
            }
            .padding(AppSpacing.medium)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ActionPromptContentHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(contentHeight <= maxHeight)
        .frame(height: min(contentHeight, maxHeight))
        .onPreferenceChange(ActionPromptContentHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            contentHeight = height
        }
        .background(
            theme.surface,
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
            .stroke(theme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
    }

    private var icon: some View {
        Image(
            systemName:
                prompt.iconSystemName
                ?? prompt.style.defaultIconSystemName
        )
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(accent)
        .frame(width: 52, height: 52)
        .background(accent.opacity(0.14), in: Circle())
        .accessibilityHidden(true)
    }

    private var copy: some View {
        VStack(spacing: AppSpacing.small) {
            Text(prompt.title)
                .appTextStyle(.sectionTitle)
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityFocused(titleIsFocused)

            if let message = prompt.message {
                Text(message)
                    .appTextStyle(.body)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let detail = prompt.detail {
                Text(detail)
                    .appTextStyle(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var actionList: some View {
        VStack(spacing: AppSpacing.small) {
            ForEach(prompt.actions) { action in
                ActionPromptButton(
                    action: action,
                    accent: accent,
                    dismiss: dismiss
                )
            }
        }
    }

    private var accent: Color {
        prompt.accent ?? defaultAccent
    }

    private var defaultAccent: Color {
        switch prompt.style {
        case .destructive:
            theme.destructive
        case .warning:
            theme.warning
        case .info:
            theme.primary
        case .completion:
            theme.success
        case .replacement:
            .purple
        }
    }
}

private struct ActionPromptContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
