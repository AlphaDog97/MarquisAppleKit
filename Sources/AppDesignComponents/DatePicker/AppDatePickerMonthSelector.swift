import AppDesignTokens
import SwiftUI

struct AppDatePickerMonthSelector: View {
    @Binding var year: Int
    @Binding var month: Int

    let yearRange: ClosedRange<Int>
    let calendar: Calendar
    let accent: Color
    let labels: AppDatePickerLabels
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            HStack(spacing: AppSpacing.large) {
                Picker(labels.monthLabel, selection: $month) {
                    ForEach(1...12, id: \.self) { month in
                        if let date = calendar.date(
                            from: DateComponents(year: year, month: month, day: 1)
                        ) {
                            Text(date, format: .dateTime.month(.wide)).tag(month)
                        }
                    }
                }

                Picker(labels.yearLabel, selection: $year) {
                    ForEach(Array(yearRange), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            }
            .padding(AppSpacing.large)
            .navigationTitle(labels.monthPickerTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onConfirm()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundStyle(accent)
                    .accessibilityLabel(labels.doneAccessibilityLabel)
                }
            }
        }
        .appDatePickerPresentation()
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
