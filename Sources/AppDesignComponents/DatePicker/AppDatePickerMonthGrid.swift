import AppDesignTokens
import SwiftUI

struct AppDatePickerMonthGrid: View {
    let month: Date
    let calendar: Calendar
    let firstWeekday: Int?
    let beginDate: Date?
    let endDate: Date?
    let isDateRange: Bool
    let minimumDate: Date?
    let maximumDate: Date?
    let excludedDates: [Date]
    let decorations: [Date: AppDatePickerDecoration]
    let accent: Color
    let theme: AppTheme
    let onSelect: (Date) -> Void

    var body: some View {
        LazyVGrid(columns: weekdayColumns, spacing: AppSpacing.extraSmall) {
            ForEach(0..<leadingSpaceCount, id: \.self) { _ in
                Color.clear.frame(height: 48)
            }

            ForEach(days, id: \.self) { date in
                AppDatePickerDayCell(
                    day: calendar.component(.day, from: date),
                    isToday: calendar.isDateInToday(date),
                    isEndpoint: isEndpoint(date),
                    isInRange: isInSelectedRange(date),
                    isEnabled: isSelectable(date),
                    accent: accent,
                    theme: theme,
                    decoration: decoration(for: date)
                ) {
                    onSelect(date)
                }
            }
        }
    }

    private var weekdayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppSpacing.extraSmall), count: 7)
    }

    private var days: [Date] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        return dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private var leadingSpaceCount: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        let first = min(max(firstWeekday ?? calendar.firstWeekday, 1), 7)
        return (weekday - first + 7) % 7
    }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private func isSelectable(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        if let minimumDate, day < calendar.startOfDay(for: minimumDate) { return false }
        if let maximumDate, day > calendar.startOfDay(for: maximumDate) { return false }
        return !excludedDates.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    private func isEndpoint(_ date: Date) -> Bool {
        if let beginDate, calendar.isDate(beginDate, inSameDayAs: date) { return true }
        if let endDate, calendar.isDate(endDate, inSameDayAs: date) { return true }
        return false
    }

    private func isInSelectedRange(_ date: Date) -> Bool {
        guard isDateRange, let beginDate, let endDate else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: beginDate) && day <= calendar.startOfDay(for: endDate)
    }

    private func decoration(for date: Date) -> AppDatePickerDecoration? {
        let day = calendar.startOfDay(for: date)
        if let exact = decorations[day] { return exact }
        return decorations.first { calendar.isDate($0.key, inSameDayAs: day) }?.value
    }
}
