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

    private var shareButton: some View {
        Button(action: onShare) {
            shareLabel
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var saveButton: some View {
        Button(action: onSave) {
            saveLabel
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .background(accent, in: Capsule())
        .opacity(isSaving ? 0.72 : 1)
    }

    private var shareLabel: some View {
        Text(labels.share)
            .appTextStyle(.control)
            .fontWeight(.semibold)
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
#endif
