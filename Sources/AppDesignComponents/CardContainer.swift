import AppDesignTokens
import SwiftUI

public struct CardContainer<Content: View>: View {
    @Environment(\.appTheme) private var theme

    private let padding: CGFloat
    private let content: Content

    public init(
        padding: CGFloat = AppSpacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(theme.surface)
            .clipShape(
                RoundedRectangle(
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
    }
}
