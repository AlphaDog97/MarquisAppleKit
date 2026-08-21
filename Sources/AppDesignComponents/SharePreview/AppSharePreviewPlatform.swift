#if canImport(UIKit) && canImport(Photos)
import AppDesignTokens
import Photos
import SwiftUI
import UIKit

struct AppSharePreviewActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }
}

enum AppSharePreviewImageRenderer {
    @MainActor
    static func render<Content: View>(
        content: Content,
        width: CGFloat,
        colorScheme: ColorScheme,
        locale: Locale,
        appTheme: AppTheme,
        scale: CGFloat? = nil
    ) -> UIImage? {
        let composedContent = content
            .frame(width: width, alignment: .leading)
            .background(appTheme.background)
            .environment(\.locale, locale)
            .environment(\.colorScheme, colorScheme)
            .appTheme(appTheme)
            .bodyMapRenderingMode(.staticExport)

        let renderer = ImageRenderer(content: composedContent)
        renderer.scale = scale ?? UIScreen.main.scale
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        return renderer.uiImage
    }
}

enum AppSharePreviewPhotoSaveError: Error {
    case accessDenied
    case saveFailed
}

final class AppSharePreviewImageBox: @unchecked Sendable {
    let image: UIImage

    init(_ image: UIImage) {
        self.image = image
    }
}

enum AppSharePreviewPhotoSaver {
    static func save(_ imageBox: AppSharePreviewImageBox) async throws {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let authorizedStatus: PHAuthorizationStatus

        if currentStatus == .notDetermined {
            authorizedStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        } else {
            authorizedStatus = currentStatus
        }

        guard authorizedStatus == .authorized || authorizedStatus == .limited else {
            throw AppSharePreviewPhotoSaveError.accessDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: imageBox.image)
            }
        } catch {
            throw AppSharePreviewPhotoSaveError.saveFailed
        }
    }
}
#endif
