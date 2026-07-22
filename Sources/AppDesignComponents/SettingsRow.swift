import AppDesignTokens
import SwiftUI

public struct SettingsRow<Trailing: View>: View {
    @Environment(\.appTheme) private var theme

    private let systemImage: String?
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing

    public init(
        systemImage: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: AppSpacing.medium) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(theme.primary)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(title)
                    .appTextStyle(.body)
                    .foregroundStyle(theme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .appTextStyle(.metadata)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer(minLength: AppSpacing.medium)
            trailing
        }
        .padding(.vertical, AppSpacing.small)
        .contentShape(Rectangle())
    }
}

public extension SettingsRow where Trailing == EmptyView {
    init(
        systemImage: String? = nil,
        title: String,
        subtitle: String? = nil
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle
        ) {
            EmptyView()
        }
    }
}
