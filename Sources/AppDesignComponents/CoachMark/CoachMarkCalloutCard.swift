import AppCore
import AppDesignTokens
import SwiftUI

struct CoachMarkCalloutCard: View {
    @Environment(\.appTheme) private var theme
    @AccessibilityFocusState private var titleIsFocused: Bool

    let step: CoachMarkStep
    let isLastStep: Bool
    let labels: CoachMarkLabels
    let maxHeight: CGFloat
    @Binding var contentHeight: CGFloat
    let onSkip: @MainActor () -> Void
    let onAdvance: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                header
                actions
            }
            .padding(AppSpacing.medium)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: CoachMarkCalloutHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(contentHeight <= maxHeight)
        .frame(height: min(contentHeight, maxHeight))
        .onPreferenceChange(CoachMarkCalloutHeightPreferenceKey.self) { height in
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
        .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
        .onAppear {
            titleIsFocused = true
        }
        .onChange(of: step.id) { _, _ in
            titleIsFocused = true
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            if let iconSystemName = step.iconSystemName {
                Image(systemName: iconSystemName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(step.title)
                    .appTextStyle(.cardTitle)
                    .foregroundStyle(theme.textPrimary)
                    .accessibilityFocused($titleIsFocused)

                Text(step.message)
                    .appTextStyle(.supporting)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: AppSpacing.small) {
            Button {
                HapticFeedback.selection()
                onSkip()
            } label: {
                Text(labels.skip)
                    .appTextStyle(.control)
                    .foregroundStyle(theme.textSecondary)
                    .frame(minHeight: 44)
                    .padding(.horizontal, AppSpacing.medium)
            }
            .buttonStyle(.plain)

            Spacer(minLength: AppSpacing.small)

            Button {
                HapticFeedback.selection()
                onAdvance()
            } label: {
                Text(isLastStep ? labels.done : labels.next)
                    .appTextStyle(.control)
                    .foregroundStyle(theme.onPrimary)
                    .frame(minHeight: 44)
                    .padding(.horizontal, AppSpacing.medium)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var accent: Color {
        step.accent ?? theme.primary
    }
}

private struct CoachMarkCalloutHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
