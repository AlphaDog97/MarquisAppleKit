#if canImport(UIKit)
import AppDesignTokens
import SwiftUI
import UIKit

/// A branded, image-renderable layout for app-defined share content.
///
/// The layout intentionally does not add a rounded card, border, or shadow.
/// Callers can provide a background view that fills the complete preview and
/// exported image, including the brand header and outer padding.
public struct AppSharePreviewCard<Content: View>: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme

    private let brand: AppSharePreviewBrand
    private let accent: Color
    private let additionalTopPadding: CGFloat
    private let backgroundView: AnyView?
    private let content: Content

    public init(
        brand: AppSharePreviewBrand = .current(),
        accent: Color,
        additionalTopPadding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.brand = brand
        self.accent = accent
        self.additionalTopPadding = additionalTopPadding
        self.backgroundView = nil
        self.content = content()
    }

    public init<Background: View>(
        brand: AppSharePreviewBrand = .current(),
        accent: Color,
        additionalTopPadding: CGFloat = 0,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.brand = brand
        self.accent = accent
        self.additionalTopPadding = additionalTopPadding
        self.backgroundView = AnyView(background())
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            brandHeader
            content
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.medium + max(0, additionalTopPadding))
        .padding(.bottom, AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if let backgroundView {
                backgroundView
            } else {
                appTheme.surface
            }
        }
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

    private var iconShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
    }

    private var iconSize: CGFloat {
        AppSpacing.extraLarge + AppSpacing.small
    }
}
#endif
