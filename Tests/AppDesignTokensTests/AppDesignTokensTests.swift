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
