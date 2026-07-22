#if canImport(UIKit)
import UIKit
#endif

public enum HapticFeedback {
    public enum ImpactStyle: Sendable {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }

    public enum NotificationStyle: Sendable {
        case success
        case warning
        case error
    }

    @MainActor
    public static func impact(_ style: ImpactStyle = .medium) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    @MainActor
    public static func selection() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }

    @MainActor
    public static func notification(_ style: NotificationStyle) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(style.uiKitStyle)
        #endif
    }
}

#if canImport(UIKit)
private extension HapticFeedback.ImpactStyle {
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        case .soft: .soft
        case .rigid: .rigid
        }
    }
}

private extension HapticFeedback.NotificationStyle {
    var uiKitStyle: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: .success
        case .warning: .warning
        case .error: .error
        }
    }
}
#endif
