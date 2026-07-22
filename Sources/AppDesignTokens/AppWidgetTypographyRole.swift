import SwiftUI

/// Semantic typography roles for WidgetKit and ActivityKit surfaces.
///
/// The scale is intentionally tighter than `AppTypographyRole` while preserving
/// the same rounded hierarchy and stable monospaced metrics.
public enum AppWidgetTypographyRole: CaseIterable, Sendable {
    case eyebrow
    case title
    case body
    case supporting
    case caption
    case control
    case metricLarge
    case metric
    case metricCompact

    public var font: Font {
        usesMonospacedDigits ? baseFont.monospacedDigit() : baseFont
    }

    public var tracking: CGFloat {
        switch self {
        case .eyebrow:
            0.7
        default:
            0
        }
    }

    public var usesMonospacedDigits: Bool {
        switch self {
        case .metricLarge, .metric, .metricCompact:
            true
        default:
            false
        }
    }

    private var baseFont: Font {
        switch self {
        case .eyebrow:
            .system(.caption2, design: .rounded, weight: .bold)
        case .title:
            .system(.headline, design: .rounded, weight: .semibold)
        case .body:
            .system(.subheadline, design: .rounded, weight: .regular)
        case .supporting:
            .system(.caption, design: .rounded, weight: .medium)
        case .caption:
            .system(.caption2, design: .rounded, weight: .regular)
        case .control:
            .system(.caption, design: .rounded, weight: .semibold)
        case .metricLarge:
            .system(.largeTitle, design: .rounded, weight: .bold)
        case .metric:
            .system(.title2, design: .rounded, weight: .bold)
        case .metricCompact:
            .system(.caption, design: .rounded, weight: .bold)
        }
    }
}
