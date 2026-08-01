import Foundation

/// User-facing copy used by ``AppSharePreviewSheet``.
///
/// Apps should pass already-localized strings so the Package does not own
/// product-specific localization tables.
public struct AppSharePreviewLabels: Equatable, Sendable {
    public var title: String
    public var share: String
    public var save: String
    public var saved: String
    public var confirm: String
    public var renderFailed: String
    public var photoAccessDenied: String
    public var saveFailed: String

    public init(
        title: String = "Share Preview",
        share: String = "Share",
        save: String = "Save",
        saved: String = "Saved to Photos",
        confirm: String = "OK",
        renderFailed: String = "Unable to create the share image.",
        photoAccessDenied: String = "Photo access is required to save this image.",
        saveFailed: String = "Unable to save the image."
    ) {
        self.title = title
        self.share = share
        self.save = save
        self.saved = saved
        self.confirm = confirm
        self.renderFailed = renderFailed
        self.photoAccessDenied = photoAccessDenied
        self.saveFailed = saveFailed
    }
}
