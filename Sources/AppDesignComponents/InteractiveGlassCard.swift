import AppDesignTokens
import SwiftUI

/// A reusable Liquid Glass surface for card-sized interactive content.
///
/// Use this view as the visual label of a `Button`, `NavigationLink`, or another
/// semantic control. The component owns only the shared card presentation so
/// navigation and business behavior remain in the consuming app.
@available(iOS 26.0, macOS 26.0, *)
public struct InteractiveGlassCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let tint: Color?
    private let content: Content

    public init(
        padding: CGFloat = AppSpacing.medium,
        cornerRadius: CGFloat = AppRadius.medium,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )

#if compiler(>=6.2)
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .contentShape(shape)
            .glassEffect(
                .regular
                    .tint(tint)
                    .interactive(),
                in: shape
            )
#else
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .contentShape(shape)
#endif
    }
}
