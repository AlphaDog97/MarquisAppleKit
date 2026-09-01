import SwiftUI

public struct AppDatePickerDecoration {
    public let badgeText: String?
    public let badgeColor: Color
    public let badgeForegroundColor: Color
    public let foregroundColor: Color?

    public init(
        badgeText: String? = nil,
        badgeColor: Color = .accentColor,
        badgeForegroundColor: Color = .white,
        foregroundColor: Color? = nil
    ) {
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.badgeForegroundColor = badgeForegroundColor
        self.foregroundColor = foregroundColor
    }
}

public struct AppDatePickerSummaryItem: Identifiable {
    public let id: String
    public let title: String
    public let color: Color

    public init(id: String, title: String, color: Color) {
        self.id = id
        self.title = title
        self.color = color
    }
}

public struct AppDatePickerLabels {
    public let rangeToggleTitle: String

    public init(rangeToggleTitle: String = "Select range") {
        self.rangeToggleTitle = rangeToggleTitle
    }
}

struct AppDatePickerSelectionLogic {
    static func select(
        _ date: Date,
        beginDate: Date?,
        endDate: Date?,
        isDateRange: Bool
    ) -> (beginDate: Date?, endDate: Date?) {
        guard isDateRange else {
            return (date, date)
        }

        guard let beginDate else {
            return (date, nil)
        }

        guard let endDate else {
            return date < beginDate ? (date, beginDate) : (beginDate, date)
        }

        if date == beginDate || date == endDate {
            return (date, date)
        }

        if date < beginDate {
            return (date, endDate)
        }

        if date > endDate {
            return (beginDate, date)
        }

        let distanceToBegin = abs(date.timeIntervalSince(beginDate))
        let distanceToEnd = abs(date.timeIntervalSince(endDate))
        return distanceToBegin <= distanceToEnd
            ? (date, endDate)
            : (beginDate, date)
    }
}
