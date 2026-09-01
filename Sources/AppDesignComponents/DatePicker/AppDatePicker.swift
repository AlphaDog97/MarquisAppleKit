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
        self._monthPickerYear = State(initialValue: components.year ?? initialCalendar.component(.year, from: initialDate))
        self._monthPickerMonth = State(initialValue: components.month ?? initialCalendar.component(.month, from: initialDate))
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
        Button {
            withAnimation(AppMotion.standard) {
                pageOffset += delta
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
        let days = daysInMonth(month)
        let leadingSpaces = leadingSpaceCount(for: month)

        return LazyVGrid(columns: weekdayColumns, spacing: AppSpacing.extraSmall) {
            ForEach(0..<leadingSpaces, id: \.self) { _ in
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
                    select(date)
                }
            }
        }
    }

    private var monthPickerSheet: some View {
        NavigationStack {
            HStack(spacing: AppSpacing.large) {
                Picker("Month", selection: $monthPickerMonth) {
                    ForEach(1...12, id: \.self) { month in
                        if let date = calendar.date(from: DateComponents(year: monthPickerYear, month: month, day: 1)) {
                            Text(date, format: .dateTime.month(.wide)).tag(month)
                        }
                    }
                }

                Picker("Year", selection: $monthPickerYear) {
                    ForEach(Array(resolvedYearRange), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            }
            .padding(AppSpacing.large)
            .navigationTitle(Text(visibleMonth, format: .dateTime.month(.wide).year()))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        applyMonthPickerSelection()
                        showsMonthPicker = false
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundStyle(accent)
                }
            }
        }
        .appDatePickerPresentation()
    }

    private var visibleMonth: Date {
        month(at: pageOffset)
    }

    private func month(at offset: Int) -> Date {
        calendar.date(byAdding: .month, value: offset, to: startOfMonth(referenceMonth)) ?? referenceMonth
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
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    private func daysInMonth(_ month: Date) -> [Date] {
        let start = startOfMonth(month)
        guard let dayRange = calendar.range(of: .day, in: .month, for: start) else { return [] }
        return dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }

    private func leadingSpaceCount(for month: Date) -> Int {
        let weekday = calendar.component(.weekday, from: startOfMonth(month))
        let first = min(max(firstWeekday ?? calendar.firstWeekday, 1), 7)
        return (weekday - first + 7) % 7
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

    private func select(_ date: Date) {
        guard isSelectable(date) else { return }
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
        monthPickerYear = calendar.component(.year, from: visibleMonth)
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

private extension View {
    @ViewBuilder
    func appDatePickerPresentation() -> some View {
        #if os(iOS)
        presentationDetents([.fraction(0.32)])
            .presentationDragIndicator(.visible)
        #else
        self
        #endif
    }
}
