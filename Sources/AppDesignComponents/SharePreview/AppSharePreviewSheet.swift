#if canImport(UIKit) && canImport(Photos)
import AppDesignTokens
import Photos
import SwiftUI
import UIKit

/// Presents branded share content, renders it as an image, and provides share
/// and save-to-Photos actions.
public struct AppSharePreviewSheet<PreviewContent: View>: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    private let brand: AppSharePreviewBrand
    private let accent: Color
    private let labels: AppSharePreviewLabels
    private let contentWidth: CGFloat
    private let exportTopPadding: CGFloat
    private let backgroundView: AnyView?
    private let previewContent: PreviewContent

    @State private var activityItem: AppSharePreviewActivityItem?
    @State private var isSaving = false
    @State private var alertMessage: String?
    @State private var measuredPreviewHeight = UIScreen.main.bounds.height * 1.6

    public init(
        brand: AppSharePreviewBrand = .current(),
        accent: Color,
        labels: AppSharePreviewLabels = AppSharePreviewLabels(),
        contentWidth: CGFloat,
        exportTopPadding: CGFloat = 0,
        @ViewBuilder content: () -> PreviewContent
    ) {
        self.brand = brand
        self.accent = accent
        self.labels = labels
        self.contentWidth = contentWidth
        self.exportTopPadding = exportTopPadding
        self.backgroundView = nil
        self.previewContent = content()
    }

    public init<Background: View>(
        brand: AppSharePreviewBrand = .current(),
        accent: Color,
        labels: AppSharePreviewLabels = AppSharePreviewLabels(),
        contentWidth: CGFloat,
        exportTopPadding: CGFloat = 0,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> PreviewContent
    ) {
        self.brand = brand
        self.accent = accent
        self.labels = labels
        self.contentWidth = contentWidth
        self.exportTopPadding = exportTopPadding
        self.backgroundView = AnyView(background())
        self.previewContent = content()
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dragIndicator
                    .padding(.top, AppSpacing.small)
                    .padding(.bottom, AppSpacing.medium)

                GeometryReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        let previewWidth = max(
                            1,
                            proxy.size.width - AppSpacing.medium * 2
                        )

                        previewCard(screenWidth: previewWidth)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, AppSpacing.medium)
                            .padding(.bottom, AppSpacing.large)
                    }
                }
            }
            .background {
                sheetBackdrop.ignoresSafeArea()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AppSharePreviewActionBar(
                    accent: accent,
                    labels: labels,
                    isSaving: isSaving,
                    onShare: shareImage,
                    onSave: saveImage
                )
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .frame(maxWidth: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(0.82), .large])
        .presentationDragIndicator(.hidden)
        .sheet(item: $activityItem) { item in
            AppSharePreviewActivityView(activityItems: [item.image])
        }
        .alert(
            labels.title,
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        alertMessage = nil
                    }
                }
            )
        ) {
            Button(labels.confirm, role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func previewCard(screenWidth: CGFloat) -> some View {
        let scale = min(1, screenWidth / renderWidth)

        return shareCard(additionalTopPadding: 0)
            .frame(width: renderWidth, alignment: .leading)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: AppSharePreviewHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            }
            .onPreferenceChange(AppSharePreviewHeightPreferenceKey.self) { height in
                guard height > 0, abs(measuredPreviewHeight - height) > 1 else {
                    return
                }
                measuredPreviewHeight = height
            }
            .scaleEffect(scale, anchor: .top)
            .frame(
                width: screenWidth,
                height: measuredPreviewHeight * scale,
                alignment: .top
            )
    }

    @ViewBuilder
    private func shareCard(additionalTopPadding: CGFloat) -> some View {
        if let backgroundView {
            AppSharePreviewCard(
                brand: brand,
                accent: accent,
                additionalTopPadding: additionalTopPadding,
                background: { backgroundView }
            ) {
                previewContent
            }
        } else {
            AppSharePreviewCard(
                brand: brand,
                accent: accent,
                additionalTopPadding: additionalTopPadding
            ) {
                previewContent
            }
        }
    }

    @ViewBuilder
    private var sheetBackdrop: some View {
        if let backgroundView {
            backgroundView
        } else {
            appTheme.surface
        }
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.24))
            .frame(
                width: AppSpacing.extraLarge + AppSpacing.large,
                height: AppSpacing.extraSmall
            )
    }

    private var renderWidth: CGFloat {
        contentWidth + AppSpacing.medium * 2
    }

    @MainActor
    private func makeImage() -> UIImage? {
        AppSharePreviewImageRenderer.render(
            content: shareCard(additionalTopPadding: exportTopPadding),
            width: renderWidth,
            colorScheme: colorScheme,
            locale: locale,
            appTheme: appTheme
        )
    }

    @MainActor
    private func shareImage() {
        guard let image = makeImage() else {
            alertMessage = labels.renderFailed
            return
        }

        activityItem = AppSharePreviewActivityItem(image: image)
    }

    @MainActor
    private func saveImage() {
        guard !isSaving else { return }
        guard let image = makeImage() else {
            alertMessage = labels.renderFailed
            return
        }

        isSaving = true
        let imageBox = AppSharePreviewImageBox(image)

        Task { @MainActor in
            do {
                try await AppSharePreviewPhotoSaver.save(imageBox)
                isSaving = false
                alertMessage = labels.saved
            } catch AppSharePreviewPhotoSaveError.accessDenied {
                isSaving = false
                alertMessage = labels.photoAccessDenied
            } catch {
                isSaving = false
                alertMessage = labels.saveFailed
            }
        }
    }
}

private struct AppSharePreviewActivityItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct AppSharePreviewHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
#endif
