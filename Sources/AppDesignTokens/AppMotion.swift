import SwiftUI

public enum AppMotion {
    public static let quickDuration = 0.16
    public static let standardDuration = 0.28
    public static let deliberateDuration = 0.42

    public static let quick = Animation.easeOut(duration: quickDuration)
    public static let standard = Animation.easeInOut(duration: standardDuration)
    public static let spring = Animation.spring(response: 0.4, dampingFraction: 0.82)
}
