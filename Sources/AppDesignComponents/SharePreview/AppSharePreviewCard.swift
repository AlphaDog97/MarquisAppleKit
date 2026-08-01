#if canImport(UIKit)
import AppDesignTokens
import SwiftUI
import UIKit

/// A branded, image-renderable container for app-defined share content.
public struct AppSharePreviewCard<Content: View>: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme

    private let brand: AppSharePreviewBrand
    private let accent: Color
    private let content: Content

    public init(
        brand: AppSharePreviewBrand = .current(),
        accent: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.brand = brand
        self.accent = accent
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            brandHeader
            content
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appTheme.surface)
        .clipShape(cardShape)
        .overlay {
            cardShape
                .strokeBorder(cardStrokeColor, lineWidth: 1)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08),
            radius: AppSpacing.medium,
            x: 0,
            y: AppSpacing.extraSmall
        )
    }

    private var brandHeader: some View {
        HStack(spacing: AppSpacing.small) {
            brandIcon

            Text(brand.name)
                .appTextStyle(.heroTitle)
                .foregroundStyle(appTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.small)
    }

    @ViewBuilder
    private var brandIcon: some View {
        if let icon = brand.icon {
            Image(uiImage: icon)
                .resizable()
                .scaledToFill()
                .frame(width: iconSize, height: iconSize)
                .clipShape(iconShape)
        } else {
            iconShape
                .fill(accent.opacity(colorScheme == .dark ? 0.28 : 0.16))
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(systemName: "app.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(accent)
                }
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
    }

    private var iconShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
    }

    private var cardStrokeColor: Color {
        accent.opacity(colorScheme == .dark ? 0.34 : 0.22)
    }

    private var iconSize: CGFloat {
        AppSpacing.extraLarge + AppSpacing.small
    }
}
#endif
