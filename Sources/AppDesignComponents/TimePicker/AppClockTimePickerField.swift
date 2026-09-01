import AppDesignTokens
import SwiftUI

public struct AppClockTimePickerField: View {
    @Environment(\.appTheme) private var theme

    private let title: String
    @Binding private var selection: Date
    private let tint: Color?
    private let labels: AppClockTimePickerLabels

    @State private var isPresented = false

    public init(
        title: String,
        selection: Binding<Date>,
        tint: Color? = nil,
        labels: AppClockTimePickerLabels = .init()
    ) {
        self.title = title
        self._selection = selection
        self.tint = tint
        self.labels = labels
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            AppClockPickerFieldLabel(
                title: title,
                primaryText: formattedTime(selection),
                secondaryText: nil,
                accent: accent
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            AppClockTimePickerSheet(
                title: title,
                selection: $selection,
                validRange: nil,
                tint: tint,
                showsDatePicker: false,
                labels: labels
            )
        }
    }

    private var accent: Color {
        tint ?? theme.primary
    }
}

public struct AppDateTimeClockPickerField: View {
    @Environment(\.appTheme) private var theme

    private let title: String
    @Binding private var selection: Date
    private let validRange: ClosedRange<Date>?
    private let tint: Color?
    private let labels: AppClockTimePickerLabels

    @State private var isPresented = false

    public init(
        title: String,
        selection: Binding<Date>,
        validRange: ClosedRange<Date>? = nil,
        tint: Color? = nil,
        labels: AppClockTimePickerLabels = .init()
    ) {
        self.title = title
        self._selection = selection
        self.validRange = validRange
        self.tint = tint
        self.labels = labels
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            AppClockPickerFieldLabel(
                title: title,
                primaryText: formattedDate(selection),
                secondaryText: formattedTime(selection),
                accent: accent
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            AppClockTimePickerSheet(
                title: title,
                selection: $selection,
                validRange: validRange,
                tint: tint,
                showsDatePicker: true,
                labels: labels
            )
        }
    }

    private var accent: Color {
        tint ?? theme.primary
    }
}

public struct AppCompactClockTimePickerButton: View {
    @Environment(\.appTheme) private var theme

    private let title: String
    @Binding private var selection: Date
    private let tint: Color?
    private let labels: AppClockTimePickerLabels

    @State private var isPresented = false

    public init(
        title: String,
        selection: Binding<Date>,
        tint: Color? = nil,
        labels: AppClockTimePickerLabels = .init()
    ) {
        self.title = title
        self._selection = selection
        self.tint = tint
        self.labels = labels
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            Text(formattedTime(selection))
                .appTextStyle(.badge)
                .monospacedDigit()
                .foregroundStyle(accent)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.extraSmall)
                .background(accent.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            AppClockTimePickerSheet(
                title: title,
                selection: $selection,
                validRange: nil,
                tint: tint,
                showsDatePicker: false,
                labels: labels
            )
        }
    }

    private var accent: Color {
        tint ?? theme.primary
    }
}

private struct AppClockPickerFieldLabel: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let primaryText: String
    let secondaryText: String?
    let accent: Color

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(title)
                    .appTextStyle(.metadata)
                    .foregroundStyle(theme.textSecondary)

                HStack(alignment: .lastTextBaseline, spacing: AppSpacing.small) {
                    Text(primaryText)
                        .appTextStyle(.cardTitle)
                        .foregroundStyle(theme.textPrimary)

                    if let secondaryText {
                        Text(secondaryText)
                            .appTextStyle(.badge)
                            .foregroundStyle(accent)
                    }
                }
                .monospacedDigit()
            }

            Spacer(minLength: AppSpacing.small)

            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(AppSpacing.medium)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

private func formattedTime(_ date: Date) -> String {
    date.formatted(date: .omitted, time: .shortened)
}

private func formattedDate(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
}
