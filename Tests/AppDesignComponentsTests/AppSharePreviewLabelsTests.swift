import Testing
@testable import AppDesignComponents

@Test("Share preview labels expose stable defaults")
func sharePreviewLabelDefaults() {
    let labels = AppSharePreviewLabels()

    #expect(labels.share == "Share")
    #expect(labels.save == "Save")
    #expect(labels.confirm == "OK")
}

@Test("Share preview labels accept app-localized copy")
func sharePreviewLocalizedLabels() {
    let labels = AppSharePreviewLabels(
        title: "分享预览",
        share: "分享",
        save: "保存",
        saved: "已保存到照片",
        confirm: "确认",
        renderFailed: "生成图片失败",
        photoAccessDenied: "需要照片权限",
        saveFailed: "保存失败"
    )

    #expect(labels.title == "分享预览")
    #expect(labels.share == "分享")
    #expect(labels.save == "保存")
}
