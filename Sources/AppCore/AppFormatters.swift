import Foundation

public enum AppDateFormatter {
    public static func string(
        from date: Date,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = locale
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
}

public enum AppNumberFormatter {
    public static func percentage(
        _ value: Double,
        fractionDigits: Int = 0,
        locale: Locale = .current
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    public static func decimal(
        _ value: Double,
        fractionDigits: Int = 0,
        locale: Locale = .current
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
