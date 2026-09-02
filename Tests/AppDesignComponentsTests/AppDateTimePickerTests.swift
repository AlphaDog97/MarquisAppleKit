import Foundation
import Testing
@testable import AppDesignComponents

@Test("Date picker single selection keeps matching endpoints")
func datePickerSingleSelection() {
    let selected = date(2026, 9, 12)
    let result = AppDatePickerSelectionLogic.select(
        selected,
        beginDate: date(2026, 9, 1),
        endDate: date(2026, 9, 5),
        isDateRange: false
    )

    #expect(result.beginDate == selected)
    #expect(result.endDate == selected)
}

@Test("Date picker range selection orders reversed endpoints")
func datePickerRangeSelectionOrdersEndpoints() {
    let begin = date(2026, 9, 12)
    let earlier = date(2026, 9, 4)
    let result = AppDatePickerSelectionLogic.select(
        earlier,
        beginDate: begin,
        endDate: nil,
        isDateRange: true
    )

    #expect(result.beginDate == earlier)
    #expect(result.endDate == begin)
}

@Test("Date picker moves the nearest endpoint for an interior selection")
func datePickerRangeSelectionMovesNearestEndpoint() {
    let begin = date(2026, 9, 1)
    let end = date(2026, 9, 10)
    let selected = date(2026, 9, 8)
    let result = AppDatePickerSelectionLogic.select(
        selected,
        beginDate: begin,
        endDate: end,
        isDateRange: true
    )

    #expect(result.beginDate == begin)
    #expect(result.endDate == selected)
}

@Test("Clock picker clamps a changed time into its valid range")
func clockPickerClampsSelection() {
    let calendar = utcCalendar
    let selection = date(2026, 9, 1, 8, 0)
    let lower = date(2026, 9, 1, 9, 0)
    let upper = date(2026, 9, 1, 17, 0)

    let result = AppClockTimeSelectionLogic.date(
        bySettingHour: 7,
        minute: 30,
        on: selection,
        calendar: calendar,
        validRange: lower...upper
    )

    #expect(result == lower)
}

private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 0,
    _ minute: Int = 0
) -> Date {
    utcCalendar.date(
        from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
    )!
}
