# Changelog

所有重要变更都会记录在此文件中。

格式参考 Keep a Changelog，并遵循语义化版本。

## [Unreleased]

## [0.1.0] - 2026-07-22

### Added

- 初始化 `AppCore`、`AppDesignTokens` 和 `AppDesignComponents`。
- 增加基础单元测试与接入文档。
- 增加 App、Widget 和 Live Activity 的 Dynamic Type 语义字体角色。
- 增加字体 View Modifier、根作用域和等宽数字指标支持。
- 增加可复用的 Coach Mark 聚光灯引导流程、目标注册和引导卡片。
- 增加统一 Action Prompt 确认框，支持信息、警告、完成、替换和破坏性操作。
- 增加 `AppDesignComponentsTests`，覆盖 Coach Mark 与 Action Prompt 公共模型。

### Changed

- 公共 SwiftUI 组件改用语义字体角色。
- GoalMaster 的引导和确认框视觉实现已移除业务命名，并改用 `AppTheme` 与 `HapticFeedback`。
