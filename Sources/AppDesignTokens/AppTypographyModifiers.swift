import SwiftUI

private struct AppTypographyStyleModifier: ViewModifier {
    let role: AppTypographyRole

    func body(content: Content) -> some View {
        content
            .font(role.font)
            .tracking(role.tracking)
            .lineSpacing(role.lineSpacing)
    }
}

private struct AppTypographyScopeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTypography.body)
            .fontDesign(.rounded)
    }
}

private struct AppWidgetTypographyStyleModifier: ViewModifier {
    let role: AppWidgetTypographyRole

    func body(content: Content) -> some View {
        content
            .font(role.font)
            .tracking(role.tracking)
    }
}

private struct AppWidgetTypographyScopeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppWidgetTypographyRole.body.font)
            .fontDesign(.rounded)
    }
}

public extension View {
    /// Applies an application semantic typography role.
    func appTextStyle(_ role: AppTypographyRole) -> some View {
        modifier(AppTypographyStyleModifier(role: role))
    }

    /// Gives legacy application text a rounded baseline during migration.
    ///
    /// Explicit `appTextStyle(_:)` roles still control reading text, hierarchy,
    /// tracking, line spacing, and monospaced metrics.
    func appTypographyScope() -> some View {
        modifier(AppTypographyScopeModifier())
    }

    /// Applies a compact semantic role for WidgetKit or ActivityKit content.
    func appWidgetTextStyle(_ role: AppWidgetTypographyRole) -> some View {
        modifier(AppWidgetTypographyStyleModifier(role: role))
    }

    /// Gives legacy widget text a rounded baseline during migration.
    func appWidgetTypographyScope() -> some View {
        modifier(AppWidgetTypographyScopeModifier())
    }
}
