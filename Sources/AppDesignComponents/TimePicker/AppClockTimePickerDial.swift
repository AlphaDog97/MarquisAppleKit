import AppDesignTokens
import SwiftUI

struct AppClockTimePickerDial: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.calendar) private var calendar

    @Binding var selection: Date
    let validRange: ClosedRange<Date>?
    @Binding var phase: AppClockTimePickerPhase
    let tint: Color?

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                Circle()
                    .fill(theme.surface)
                    .overlay(Circle().stroke(theme.border, lineWidth: 1))
                    .frame(width: size, height: size)
                    .position(center)

                clockHand(size: size, center: center)

                ForEach(marks) { mark in
                    clockMark(mark, size: size, center: center)
                }

                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                    .position(center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        updateSelection(
                            from: value.location,
                            center: center,
                            size: size,
                            shouldAdvancePhase: false
                        )
                    }
                    .onEnded { value in
                        updateSelection(
                            from: value.location,
                            center: center,
                            size: size,
                            shouldAdvancePhase: phase == .hour
                        )
                    }
            )
            .animation(AppMotion.quick, value: selectedHour)
            .animation(AppMotion.quick, value: selectedMinute)
            .animation(AppMotion.quick, value: phase)
        }
        .frame(height: 292)
    }

    private var accent: Color {
        tint ?? theme.primary
    }

    private func clockHand(size: CGFloat, center: CGPoint) -> some View {
        let endpoint = handEndpoint(size: size, center: center)

        return ZStack {
            Path { path in
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))

            Circle()
                .fill(accent)
                .frame(width: 14, height: 14)
                .position(endpoint)
        }
    }

    private func clockMark(_ mark: AppClockTimeMark, size: CGFloat, center: CGPoint) -> some View {
        let isSelected = mark.value == selectedValue
        let position = point(
            for: mark.angleRatio,
            radius: mark.radiusRatio * size,
            center: center
        )

        return Text(mark.label)
            .font(.system(
                size: isSelected ? 16 : 15,
                weight: isSelected ? .bold : .semibold,
                design: .rounded
            ))
            .foregroundStyle(isSelected ? Color.white : theme.textSecondary)
            .frame(width: 44, height: 44)
            .background(Circle().fill(isSelected ? accent : Color.clear))
            .position(position)
            .contentShape(Circle())
            .onTapGesture {
                apply(mark.value)
                advanceToMinutePhaseIfNeeded()
            }
    }

    private var marks: [AppClockTimeMark] {
        phase == .hour ? hourMarks : minuteMarks
    }

    private var hourMarks: [AppClockTimeMark] {
        let outer = (1...12).map { hour in
            AppClockTimeMark(
                id: "outer-\(hour)",
                label: appTwoDigit(hour),
                value: hour,
                angleRatio: Double(hour % 12) / 12,
                radiusRatio: 0.38
            )
        }

        let inner = (Array(13...23) + [0]).map { hour in
            AppClockTimeMark(
                id: "inner-\(hour)",
                label: appTwoDigit(hour),
                value: hour,
                angleRatio: Double(hour % 12) / 12,
                radiusRatio: 0.26
            )
        }

        return outer + inner
    }

    private var minuteMarks: [AppClockTimeMark] {
        stride(from: 0, through: 55, by: 5).map { minute in
            AppClockTimeMark(
                id: "minute-\(minute)",
                label: appTwoDigit(minute),
                value: minute,
                angleRatio: Double(minute) / 60,
                radiusRatio: 0.38
            )
        }
    }

    private func handEndpoint(size: CGFloat, center: CGPoint) -> CGPoint {
        switch phase {
        case .hour:
            let radiusRatio: CGFloat = (selectedHour == 0 || selectedHour >= 13) ? 0.26 : 0.38
            return point(
                for: Double(selectedHour % 12) / 12,
                radius: radiusRatio * size,
                center: center
            )
        case .minute:
            return point(
                for: Double(selectedMinute) / 60,
                radius: 0.38 * size,
                center: center
            )
        }
    }

    private func point(for angleRatio: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = (angleRatio * 2 * .pi) - (.pi / 2)
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
    }

    private func updateSelection(
        from location: CGPoint,
        center: CGPoint,
        size: CGFloat,
        shouldAdvancePhase: Bool
    ) {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = hypot(dx, dy)

        guard distance > 12, distance <= size / 2 + 28 else { return }

        var angle = atan2(dy, dx) + (.pi / 2)
        if angle < 0 {
            angle += 2 * .pi
        }

        switch phase {
        case .hour:
            let slot = Int((angle / (2 * .pi) * 12).rounded()) % 12
            let usesInnerRing = distance < size * 0.32
            let hour = usesInnerRing
                ? (slot == 0 ? 0 : slot + 12)
                : (slot == 0 ? 12 : slot)
            apply(hour)

            if shouldAdvancePhase {
                withAnimation(AppMotion.quick) {
                    phase = .minute
                }
            }
        case .minute:
            let minute = Int((angle / (2 * .pi) * 60).rounded()) % 60
            apply(minute)
        }
    }

    private func apply(_ value: Int) {
        switch phase {
        case .hour:
            setSelection(hour: value, minute: selectedMinute)
        case .minute:
            setSelection(hour: selectedHour, minute: value)
        }
    }

    private func setSelection(hour: Int, minute: Int) {
        guard let date = AppClockTimeSelectionLogic.date(
            bySettingHour: hour,
            minute: minute,
            on: selection,
            calendar: calendar,
            validRange: validRange
        ) else { return }
        selection = date
    }

    private func advanceToMinutePhaseIfNeeded() {
        guard phase == .hour else { return }
        withAnimation(AppMotion.quick) {
            phase = .minute
        }
    }

    private var selectedHour: Int {
        calendar.component(.hour, from: selection)
    }

    private var selectedMinute: Int {
        calendar.component(.minute, from: selection)
    }

    private var selectedValue: Int {
        phase == .hour ? selectedHour : selectedMinute
    }
}
