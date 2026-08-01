# Share Preview

`AppSharePreviewSheet` is the shared, business-agnostic image sharing surface for iOS and Mac Catalyst apps.

It owns:

- the app icon and app name header;
- the renderable card container;
- preview scaling and vertical scrolling;
- image rendering;
- the system share sheet;
- save-to-Photos permission and persistence;
- the bottom Share and Save actions.

The host app continues to own the middle content, accent color, localization, business data, and any domain-specific layout.

## Usage

```swift
import AppDesignComponents
import SwiftUI

struct ProgressShareView: View {
    let accent: Color

    var body: some View {
        AppSharePreviewSheet(
            accent: accent,
            labels: AppSharePreviewLabels(
                title: localized("share.preview.title"),
                share: localized("share.preview.share"),
                save: localized("share.preview.save"),
                saved: localized("share.preview.saved"),
                confirm: localized("confirm"),
                renderFailed: localized("share.preview.renderFailed"),
                photoAccessDenied: localized("share.preview.photoAccessDenied"),
                saveFailed: localized("share.preview.saveFailed")
            ),
            contentWidth: 390
        ) {
            ProgressCardContent()
        }
    }
}
```

By default, `AppSharePreviewBrand.current()` reads `CFBundleDisplayName`, `CFBundleName`, and the primary app icon from `Bundle.main`. An app can inject a different identity:

```swift
AppSharePreviewSheet(
    brand: AppSharePreviewBrand(
        name: "Example",
        icon: UIImage(named: "ShareBrandIcon")
    ),
    accent: .blue,
    contentWidth: 390
) {
    ShareContent()
}
```

## Integration requirements

The host app must provide `NSPhotoLibraryAddUsageDescription` because saving uses add-only Photos authorization.

The component is available when UIKit and Photos are available. Native macOS targets can continue using their platform-specific export flow while sharing the same domain content views.
