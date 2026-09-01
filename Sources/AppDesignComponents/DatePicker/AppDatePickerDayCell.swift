import AppDesignTokens
import SwiftUI

struct AppDatePickerDayCell: View {
    let day: Int
    let isToday: Bool
    let isEndpoint: Bool
    let isInRange: Bool
    let isEnabled: Bool
    let accent: Color
    let theme: AppTheme
    let decoration: AppDatePickerDecoration?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Text(String(day))
                    .font(.system(.body, design: .rounded, weight: isToday ? .bold : .medium))
                    .monospacedDigit()
                    .foregroundStyle(foregroundColor)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selectionBackground)
                    .overlay(todayOutline)

                if let badgeText = decoration?.badgeText {
                    Text(badgeText)
                        .appTextStyle(.badge)
                        .foregroundStyle(decoration?.badgeForegroundColor ?? .white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(decoration?.badgeColor ?? accent, in: Capsule())
                        .offset(x: 2, y: -3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(String(day))
        .accessibilityAddTraits(isEndpoint ? .isSelected : [])
    }

    private var foregroundColor: Color {
        guard isEnabled else { return theme.textSecondary.opacity(0.45) }
        if isEndpoint { return .white }
        if let foregroundColor = decoration?.foregroundColor { return foregroundColor }
        if isInRange || isToday { return accent }
        return theme.textPrimary
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if isEndpoint {
            Circle().fill(accent)
        } else if isInRange {
            Circle().fill(accent.opacity(0.14))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var todayOutline: some View {
        if isToday && !isEndpoint {
            Circle().stroke(accent.opacity(0.5), lineWidth: 1)
        }
    }
}
