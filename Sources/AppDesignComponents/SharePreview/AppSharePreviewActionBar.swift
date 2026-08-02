#if canImport(UIKit)
import AppDesignTokens
import SwiftUI
import UIKit

struct AppSharePreviewActionBar: View {
    let accent: Color
    let labels: AppSharePreviewLabels
    let isSaving: Bool
    let onShare: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            shareButton
            saveButton
        }
    }

    @ViewBuilder
    private var shareButton: some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(action: onShare) {
                shareLabel
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(.green)
        } else {
            legacyShareButton
        }
#else
        legacyShareButton
#endif
    }

    @ViewBuilder
    private var saveButton: some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(action: onSave) {
                saveLabel
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(accent)
            .disabled(isSaving)
            .opacity(isSaving ? 0.72 : 1)
        } else {
            legacySaveButton
        }
#else
        legacySaveButton
#endif
    }

    private var legacyShareButton: some View {
        Button(action: onShare) {
            shareLabel
        }
        .buttonStyle(AppSharePreviewLegacyGlassButtonStyle(tint: .green))
    }

    private var legacySaveButton: some View {
        Button(action: onSave) {
            saveLabel
        }
        .buttonStyle(AppSharePreviewLegacyGlassButtonStyle(tint: accent))
        .disabled(isSaving)
        .opacity(isSaving ? 0.72 : 1)
    }

    private var shareLabel: some View {
        Text(labels.share)
            .appTextStyle(.control)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.extraLarge + AppSpacing.small)
    }

    private var saveLabel: some View {
        HStack(spacing: AppSpacing.small) {
            if isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "arrow.down.to.line.compact")
                    .font(.headline.weight(.bold))
            }

            Text(labels.save)
                .appTextStyle(.control)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: AppSpacing.extraLarge + AppSpacing.small)
    }
}

private struct AppSharePreviewLegacyGlassButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(tint.opacity(configuration.isPressed ? 0.68 : 0.82))
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
#endif
