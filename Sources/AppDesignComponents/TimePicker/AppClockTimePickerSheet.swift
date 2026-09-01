import AppDesignTokens
import SwiftUI

struct AppClockTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.calendar) private var calendar

    let title: String
    @Binding var selection: Date
    let validRange: ClosedRange<Date>?
    let tint: Color?
    let showsDatePicker: Bool
    let labels: AppClockTimePickerLabels

    @State private var phase: AppClockTimePickerPhase = .hour

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.large) {
                timeHeader

                if showsDatePicker {
                    dateSelectionRow
                }

                AppClockTimePickerDial(
                    selection: $selection,
                    validRange: validRange,
                    phase: $phase,
                    tint: tint
                )
                .padding(.horizontal, AppSpacing.medium)

                Spacer(minLength: 0)
            }
            .padding(.top, AppSpacing.medium)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent)
                    .accessibilityLabel(labels.doneAccessibilityLabel)
                }
            }
        }
        .appClockPickerPresentation(showsDatePicker: showsDatePicker)
    }

    private var accent: Color {
        tint ?? theme.primary
    }

    private var timeHeader: some View {
        HStack(spacing: AppSpacing.small) {
            headerButton(
                text: appTwoDigit(hour),
                phase: .hour,
                accessibilityLabel: labels.hourAccessibilityLabel
            )

            Text(":")
                .font(.system(size: 54, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.bottom, 6)

            headerButton(
                text: appTwoDigit(minute),
                phase: .minute,
                accessibilityLabel: labels.minuteAccessibilityLabel
            )
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(accent)
        )
        .padding(.horizontal, AppSpacing.large)
    }

    private var dateSelectionRow: some View {
        HStack(spacing: AppSpacing.small) {
            Text(title)
                .appTextStyle(.metadata)
                .foregroundStyle(theme.textSecondary)

            Spacer()

            if let validRange {
                DatePicker(
                    title,
                    selection: $selection,
                    in: validRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(accent)
            } else {
                DatePicker(
                    title,
                    selection: $selection,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(accent)
            }
        }
        .padding(.horizontal, AppSpacing.large)
    }

    private func headerButton(
        text: String,
        phase targetPhase: AppClockTimePickerPhase,
        accessibilityLabel: String
    ) -> some View {
        Button {
            withAnimation(AppMotion.quick) {
                phase = targetPhase
            }
        } label: {
            Text(text)
                .font(.system(size: 64, weight: .medium, design: .rounded))
                .foregroundStyle(phase == targetPhase ? .white : .white.opacity(0.52))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var hour: Int {
        calendar.component(.hour, from: selection)
    }

    private var minute: Int {
        calendar.component(.minute, from: selection)
    }
}

private extension View {
    @ViewBuilder
    func appClockPickerPresentation(showsDatePicker: Bool) -> some View {
        #if os(iOS)
        presentationDetents([.height(showsDatePicker ? 560 : 500), .large])
            .presentationDragIndicator(.visible)
        #else
        self
        #endif
    }
}
