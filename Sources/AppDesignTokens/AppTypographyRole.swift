import SwiftUI

/// Semantic typography roles for application surfaces.
///
/// High-emphasis titles, controls, badges, and metrics use SF Rounded. Reading
/// text keeps the default system design. Every role is backed by Dynamic Type.
public enum AppTypographyRole: CaseIterable, Sendable {
    case display
    case pageTitle
    case navigationTitle
    case heroTitle
    case eyebrow
    case sectionTitle
    case cardTitle
    case body
    case supporting
    case metadata
    case caption
    case control
    case badge
    case metricLarge
    case metric
    case metricCompact

    public var font: Font {
        usesMonospacedDigits ? baseFont.monospacedDigit() : baseFont
    }

    public var lineSpacing: CGFloat {
        switch self {
        case .body:
            3
        case .supporting:
            2
        case .metadata, .caption:
            1
        default:
            0
        }
    }

    public var tracking: CGFloat {
        switch self {
        case .eyebrow:
            1.2
        case .badge:
            0.2
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
        case .display:
            .system(.largeTitle, design: .rounded, weight: .heavy)
        case .pageTitle:
            .system(.largeTitle, design: .rounded, weight: .bold)
        case .navigationTitle:
            .system(.title2, design: .rounded, weight: .bold)
        case .heroTitle:
            .system(.title, design: .rounded, weight: .bold)
        case .eyebrow:
            .system(.caption, design: .rounded, weight: .bold)
        case .sectionTitle:
            .system(.title3, design: .rounded, weight: .semibold)
        case .cardTitle:
            .system(.headline, design: .rounded, weight: .semibold)
        case .body:
            .system(.body, design: .default, weight: .regular)
        case .supporting:
            .system(.subheadline, design: .default, weight: .regular)
        case .metadata:
            .system(.caption, design: .default, weight: .medium)
        case .caption:
            .system(.caption2, design: .default, weight: .regular)
        case .control:
            .system(.subheadline, design: .rounded, weight: .semibold)
        case .badge:
            .system(.caption2, design: .rounded, weight: .bold)
        case .metricLarge:
            .system(.largeTitle, design: .rounded, weight: .bold)
        case .metric:
            .system(.title, design: .rounded, weight: .bold)
        case .metricCompact:
            .system(.headline, design: .rounded, weight: .semibold)
        }
    }
}
