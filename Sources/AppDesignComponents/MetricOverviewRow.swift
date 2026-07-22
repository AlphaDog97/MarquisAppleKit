import AppDesignTokens
import SwiftUI

public struct MetricOverviewRow: View {
    @Environment(\.appTheme) private var theme

    private let title: String
    private let value: String
    private let subtitle: String?

    public init(
        title: String,
        value: String,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(theme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer(minLength: AppSpacing.medium)

            Text(value)
                .font(AppTypography.title)
                .foregroundStyle(theme.primary)
                .monospacedDigit()
        }
    }
}
