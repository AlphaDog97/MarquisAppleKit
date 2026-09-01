import Foundation

public struct AppClockTimePickerLabels {
    public let hourAccessibilityLabel: String
    public let minuteAccessibilityLabel: String
    public let doneAccessibilityLabel: String

    public init(
        hourAccessibilityLabel: String = "Hour",
        minuteAccessibilityLabel: String = "Minute",
        doneAccessibilityLabel: String = "Done"
    ) {
        self.hourAccessibilityLabel = hourAccessibilityLabel
        self.minuteAccessibilityLabel = minuteAccessibilityLabel
        self.doneAccessibilityLabel = doneAccessibilityLabel
    }
}

enum AppClockTimePickerPhase: Equatable {
    case hour
    case minute
}

struct AppClockTimeMark: Identifiable {
    let id: String
    let label: String
    let value: Int
    let angleRatio: Double
    let radiusRatio: CGFloat
}

enum AppClockTimeSelectionLogic {
    static func date(
        bySettingHour hour: Int,
        minute: Int,
        on selection: Date,
        calendar: Calendar,
        validRange: ClosedRange<Date>?
    ) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: selection)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.nanosecond = 0

        guard let date = calendar.date(from: components) else { return nil }
        guard let validRange else { return date }
        return min(max(date, validRange.lowerBound), validRange.upperBound)
    }
}

func appTwoDigit(_ value: Int) -> String {
    String(format: "%02d", value)
}
