import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct AppTheme: @unchecked Sendable {
    public let primary: Color
    public let onPrimary: Color
    public let background: Color
    public let surface: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let border: Color
    public let success: Color
    public let warning: Color
    public let destructive: Color

    public init(
        primary: Color,
        onPrimary: Color,
        background: Color,
        surface: Color,
        textPrimary: Color,
        textSecondary: Color,
        border: Color,
        success: Color,
        warning: Color,
        destructive: Color
    ) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.background = background
        self.surface = surface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.border = border
        self.success = success
        self.warning = warning
        self.destructive = destructive
    }

    public static let `default` = AppTheme(
        primary: .accentColor,
        onPrimary: .white,
        background: PlatformColors.background,
        surface: PlatformColors.surface,
        textPrimary: .primary,
        textSecondary: .secondary,
        border: .primary.opacity(0.12),
        success: .green,
        warning: .orange,
        destructive: .red
    )
}

private enum AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.default
}

public extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

public extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
}

private enum PlatformColors {
    static var background: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        .white
        #endif
    }

    static var surface: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.primary.opacity(0.06)
        #endif
    }
}
