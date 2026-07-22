import Foundation
import Testing
@testable import AppCore

@Test("AppError exposes its message")
func appErrorDescription() {
    let error = AppError.invalidInput("Missing value")
    #expect(error.errorDescription == "Missing value")
}

@Test("Collection safe subscript handles valid and invalid indexes")
func collectionSafeSubscript() {
    let values = ["A", "B"]
    #expect(values[safe: 0] == "A")
    #expect(values[safe: 2] == nil)
}

@Test("Formatters respect explicit locale and precision")
func formatterOutput() {
    let locale = Locale(identifier: "en_US_POSIX")
    let timeZone = TimeZone(secondsFromGMT: 0)!
    let date = Date(timeIntervalSince1970: 0)

    #expect(
        AppDateFormatter.string(
            from: date,
            dateStyle: .short,
            locale: locale,
            timeZone: timeZone
        ) == "1/1/70"
    )
    #expect(AppNumberFormatter.percentage(0.256, fractionDigits: 1, locale: locale) == "25.6%")
    #expect(AppNumberFormatter.decimal(1234.5, fractionDigits: 1, locale: locale) == "1,234.5")
}
