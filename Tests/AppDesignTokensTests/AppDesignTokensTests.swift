import Testing
@testable import AppDesignTokens

@Test("Layout tokens preserve their intended scale")
func layoutTokenScale() {
    #expect(AppSpacing.extraSmall < AppSpacing.small)
    #expect(AppSpacing.small < AppSpacing.medium)
    #expect(AppSpacing.medium < AppSpacing.large)
    #expect(AppRadius.small < AppRadius.medium)
    #expect(AppRadius.medium < AppRadius.large)
}

@Test("Application typography exposes the complete semantic role scale")
func appTypographyRoleScale() {
    #expect(AppTypographyRole.allCases.count == 16)
    #expect(AppTypographyRole.eyebrow.tracking > 0)
    #expect(AppTypographyRole.body.lineSpacing > 0)
    #expect(AppTypographyRole.metric.usesMonospacedDigits)
    #expect(!AppTypographyRole.body.usesMonospacedDigits)
}

@Test("Widget typography uses a compact semantic role scale")
func widgetTypographyRoleScale() {
    #expect(AppWidgetTypographyRole.allCases.count == 9)
    #expect(AppWidgetTypographyRole.eyebrow.tracking > 0)
    #expect(AppWidgetTypographyRole.metricCompact.usesMonospacedDigits)
    #expect(!AppWidgetTypographyRole.body.usesMonospacedDigits)
}
