import AppDesignTokens
import SwiftUI

public struct PrimaryButton: View {
    @Environment(\.appTheme) private var theme

    private let title: String
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                if isLoading {
                    ProgressView()
                        .tint(theme.onPrimary)
                }

                Text(title)
                    .font(AppTypography.headline)
            }
            .foregroundStyle(theme.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .background(theme.primary)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.55 : 1)
        .animation(AppMotion.quick, value: isLoading)
        .accessibilityLabel(Text(title))
    }
}
