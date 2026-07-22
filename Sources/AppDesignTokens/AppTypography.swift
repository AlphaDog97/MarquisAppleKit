import SwiftUI

public enum AppTypography {
    public static let largeTitle = Font.system(
        size: 34,
        weight: .bold,
        design: .rounded
    )

    public static let title = Font.system(
        size: 24,
        weight: .bold,
        design: .rounded
    )

    public static let headline = Font.system(
        size: 17,
        weight: .semibold
    )

    public static let body = Font.system(
        size: 17,
        weight: .regular
    )

    public static let caption = Font.system(
        size: 13,
        weight: .medium
    )

    public static func custom(
        _ postScriptName: String,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(postScriptName, size: size, relativeTo: textStyle)
    }
}
