import AppDesignTokens
import SwiftUI

public struct LoadingStateView: View {
    @Environment(\.appTheme) private var theme

    private let message: String

    public init(_ message: String = "Loading…") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .tint(theme.primary)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.large)
    }
}

public struct EmptyStateView: View {
    @Environment(\.appTheme) private var theme

    private let systemImage: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(theme.primary)

            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(theme.textPrimary)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppTypography.headline)
                    .foregroundStyle(theme.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.large)
    }
}
