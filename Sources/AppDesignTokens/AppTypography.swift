import SwiftUI

/// Font aliases for APIs that require a concrete `Font`.
///
/// Prefer `appTextStyle(_:)` in new SwiftUI views because it also applies the
/// role's tracking and line spacing.
public enum AppTypography {
    public static let display = AppTypographyRole.display.font
    public static let pageTitle = AppTypographyRole.pageTitle.font
    public static let navigationTitle = AppTypographyRole.navigationTitle.font
    public static let heroTitle = AppTypographyRole.heroTitle.font
    public static let eyebrow = AppTypographyRole.eyebrow.font
    public static let sectionTitle = AppTypographyRole.sectionTitle.font
    public static let cardTitle = AppTypographyRole.cardTitle.font
    public static let body = AppTypographyRole.body.font
    public static let supporting = AppTypographyRole.supporting.font
    public static let metadata = AppTypographyRole.metadata.font
    public static let caption = AppTypographyRole.caption.font
    public static let control = AppTypographyRole.control.font
    public static let badge = AppTypographyRole.badge.font
    public static let metricLarge = AppTypographyRole.metricLarge.font
    public static let metric = AppTypographyRole.metric.font
    public static let metricCompact = AppTypographyRole.metricCompact.font

    // Compatibility aliases retained for the package's initial API.
    public static let largeTitle = pageTitle
    public static let title = heroTitle
    public static let headline = cardTitle

    public static func custom(
        _ postScriptName: String,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(postScriptName, size: size, relativeTo: textStyle)
    }
}
