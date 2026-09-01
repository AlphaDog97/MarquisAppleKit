import AppDesignTokens
import SwiftUI

public struct AppDatePicker: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.calendar) private var calendar

    @Binding private var beginDate: Date?
    @Binding private var endDate: Date?
    @Binding private var isDateRange: Bool

    private let accentColor: Color?
    private let minimumDate: Date?
    private let maximumDate: Date?
    private let excludedDates: [Date]
    private let firstWeekday: Int?
    private let showsDateRangeToggle: Bool
    private let labels: AppDatePickerLabels
    private let decorations: [Date: AppDatePickerDecoration]
    private let monthSummary: [AppDatePickerSummaryItem]
    private let yearRange: ClosedRange<Int>?
    private let onVisibleMonthChange: ((Date) -> Void)?

    @State private var referenceMonth: Date
    @State private var pageOffset = 0
    @State private var showsMonthPicker = false
    @State private var monthPickerYear: Int
    @State private var monthPickerMonth: Int

    public init(
        beginDate: Binding<Date?>,
        endDate: Binding<Date?>,
        isDateRange: Binding<Bool>,
        accentColor: Color? = nil,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        excludedDates: [Date] = [],
        firstWeekday: Int? = nil,
        showsDateRangeToggle: Bool = false,
        labels: AppDatePickerLabels = .init(),
        decorations: [Date: AppDatePickerDecoration] = [:],
        monthSummary: [AppDatePickerSummaryItem] = [],
        yearRange: ClosedRange<Int>? = nil,
        onVisibleMonthChange: ((Date) -> Void)? = nil
    ) {
        self._beginDate = beginDate
        self._endDate = endDate
        self._isDateRange = isDateRange
        self.accentColor = accentColor
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.excludedDates = excludedDates
        self.firstWeekday = firstWeekday
        self.showsDateRangeToggle = showsDateRangeToggle
        self.labels = labels
        self.decorations = decorations
        self.monthSummary = monthSummary
        self.yearRange = yearRange
        self.onVisibleMonthChange = onVisibleMonthChange

        let initialDate = beginDate.wrappedValue ?? Date()
        let initialCalendar = Calendar.autoupdatingCurrent
        let components = initialCalendar.dateComponents([.year, .month], from: initialDate)
        let month = initialCalendar.date(from: components) ?? initialDate
        self._referenceMonth = State(initialValue: month)
        self._monthPickerYear = State(
            initialValue: components.year ?? initialCalendar.component(.year, from: initialDate)
        )
        self._monthPickerMonth = State(
            initialValue: components.month ?? initialCalendar.component(.month, from: initialDate)
        )
    }

    public var body: some View {
        VStack(spacing: AppSpacing.small) {
            header

            if !monthSummary.isEmpty {
                summaryRow
            }

            weekdayHeader
            monthPager

            if showsDateRangeToggle {
                Toggle(labels.rangeToggleTitle, isOn: $isDateRange)
                    .appTextStyle(.supporting)
                    .tint(accent)
                    .onChange(of: isDateRange) { _, isRange in
                        if !isRange, let beginDate {
                            endDate = beginDate
                        }
                    }
                    .padding(.top, AppSpacing.extraSmall)
            }
        }
        .tint(accent)
        .sheet(isPresented: $showsMonthPicker) {
            monthPickerSheet
        }
        .onAppear {
            syncMonthPickerState()
            onVisibleMonthChange?(visibleMonth)
        }
        .onChange(of: pageOffset) { _, _ in
            syncMonthPickerState()
            onVisibleMonthChange?(visibleMonth)
        }
    }

    private var accent: Color {
        accentColor ?? theme.primary
    }

    private var header: some View {
        HStack(spacing: AppSpacing.small) {
            Button {
                syncMonthPickerState()
                showsMonthPicker = true
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Text(visibleMonth, format: .dateTime.month(.wide).year())
                        .appTextStyle(.cardTitle)
                        .foregroundStyle(theme.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: AppSpacing.extraSmall) {
                monthNavigationButton(systemImage: "chevron.left", delta: -1)
                monthNavigationButton(systemImage: "chevron.right", delta: 1)
            }
        }
    }

    private func monthNavigationButton(systemImage: String, delta: Int) -> some View {
        let targetOffset = pageOffset + delta

        return Button {
            guard (-120...120).contains(targetOffset) else { return }
            withAnimation(AppMotion.standard) {
                pageOffset = targetOffset
            }
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .frame(width: 36, height: 36)
                .background(theme.surface, in: Circle())
                .overlay(Circle().stroke(theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!(-120...120).contains(targetOffset))
    }

    private var summaryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(monthSummary) { item in
                    Text(item.title)
                        .appTextStyle(.caption)
                        .foregroundStyle(item.color)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.extraSmall)
                        .background(item.color.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: weekdayColumns, spacing: AppSpacing.extraSmall) {
            ForEach(Array(localizedWeekdays.enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .appTextStyle(.metadata)
                    .foregroundStyle(theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var monthPager: some View {
        #if os(iOS)
        TabView(selection: $pageOffset) {
            ForEach(-120...120, id: \.self) { offset in
                monthGrid(for: month(at: offset))
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 320)
        #else
        monthGrid(for: visibleMonth)
            .frame(height: 320)
        #endif
    }

    private func monthGrid(for month: Date) -> some View {
        AppDatePickerMonthGrid(
            month: month,
            calendar: calendar,
            firstWeekday: firstWeekday,
            beginDate: beginDate,
            endDate: endDate,
            isDateRange: isDateRange,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            excludedDates: excludedDates,
            decorations: decorations,
            accent: accent,
            theme: theme,
            onSelect: select
        )
    }

    private var monthPickerSheet: some View {
        AppDatePickerMonthSelector(
            year: $monthPickerYear,
            month: $monthPickerMonth,
            yearRange: resolvedYearRange,
            calendar: calendar,
            accent: accent,
            labels: labels
        ) {
            applyMonthPickerSelection()
            showsMonthPicker = false
        }
    }

    private var visibleMonth: Date {
        month(at: pageOffset)
    }

    private func month(at offset: Int) -> Date {
        calendar.date(
            byAdding: .month,
            value: offset,
            to: startOfMonth(referenceMonth)
        ) ?? referenceMonth
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private var resolvedYearRange: ClosedRange<Int> {
        if let yearRange {
            return yearRange
        }
        let currentYear = calendar.component(.year, from: Date())
        return (currentYear - 100)...(currentYear + 100)
    }

    private var weekdayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppSpacing.extraSmall), count: 7)
    }

    private var localizedWeekdays: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        guard !symbols.isEmpty else { return [] }
        let requestedFirst = min(max(firstWeekday ?? calendar.firstWeekday, 1), symbols.count)
        let startIndex = requestedFirst - 1
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    private func select(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        let selection = AppDatePickerSelectionLogic.select(
            day,
            beginDate: beginDate.map(calendar.startOfDay(for:)),
            endDate: endDate.map(calendar.startOfDay(for:)),
            isDateRange: isDateRange
        )
        beginDate = selection.beginDate
        endDate = selection.endDate
    }

    private func syncMonthPickerState() {
        let visibleYear = calendar.component(.year, from: visibleMonth)
        monthPickerYear = min(max(visibleYear, resolvedYearRange.lowerBound), resolvedYearRange.upperBound)
        monthPickerMonth = calendar.component(.month, from: visibleMonth)
    }

    private func applyMonthPickerSelection() {
        guard let month = calendar.date(
            from: DateComponents(year: monthPickerYear, month: monthPickerMonth, day: 1)
        ) else { return }

        referenceMonth = month
        pageOffset = 0
        onVisibleMonthChange?(month)
    }
}
