# Changelog

所有重要变更都会记录在此文件中。

格式参考 Keep a Changelog，并遵循语义化版本。

## [Unreleased]

### Added

- 初始化 `AppCore`、`AppDesignTokens` 和 `AppDesignComponents`。
- 增加基础单元测试与接入文档。
- 增加 App、Widget 和 Live Activity 的 Dynamic Type 语义字体角色。
- 增加字体 View Modifier、根作用域和等宽数字指标支持。
- 增加可复用的 Coach Mark 聚光灯引导流程、目标注册和引导卡片。
- 增加统一 Action Prompt 确认框，支持信息、警告、完成、替换和破坏性操作。
- 增加包含 App 图标、App 名称、自定义内容、系统分享与保存到照片操作的 `AppSharePreviewSheet`。
- 增加 `AppDesignComponentsTests`，覆盖 Coach Mark、Action Prompt 与 Share Preview 公共模型。
- 增加业务无关的 `AppDatePicker`，支持单日/范围选择、日期约束、排除日期、首日配置和可注入日期装饰。
- 增加 `AppClockTimePickerField`、`AppDateTimeClockPickerField` 与 `AppCompactClockTimePickerButton`，提供 24 小时双环表盘和日期时间组合选择。
- 增加公开 `BodyMapMorphology` 几何能力，支持肩、胸、腰、臀、上臂、前臂、大腿和小腿的受控区域 envelope scale。
- 增加 BodyMap Morphology 的 Metal 实时渲染、static export、placeholder 与 hit testing 一致性支持。

### Changed

- 公共 SwiftUI 组件改用语义字体角色。
- GoalMaster 的引导和确认框视觉实现已移除业务命名，并改用 `AppTheme` 与 `HapticFeedback`。
- `BodyMapAppearance` 重新公开 `inactiveColor`，允许业务侧覆盖人体基础轮廓颜色；`baseOpacity`、背景色和 glow 开关继续由 `BodyMap` 内部控制。
- BodyMap Morphology 默认保持 `.neutral`，未显式传入形态参数时继续使用现有视觉、颜色、Glow、Selection、Reveal、资源和交互行为。
- 四肢 Morphology 围绕各自局部肢体中心调整粗细，避免改变手臂位置或双腿站距；躯干继续围绕人体中线平滑变形。
- Morphology 更新不会参与既有颜色 transition，确保实时点击区域始终与当前几何状态一致。

### Fixed

- Coach Mark Overlay 会在延伸到全屏前保留真实安全区，避免说明卡进入状态栏或灵动岛区域。
- `BodyMap` 人体轮廓底色在浅色和深色模式下默认统一使用 `Color.black.opacity(0.6)`，组件容器背景保持透明。
