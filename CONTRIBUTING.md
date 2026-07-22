# Contributing

## 基本原则

`MarquisAppleKit` 不是通用代码垃圾桶。提交新能力前，先确认它具有跨 App 的稳定复用价值。

## 分支与提交

- 分支使用 `feature/`、`fix/` 或 `refactor/` 前缀。
- 一个 Pull Request 只解决一个明确问题。
- 提交信息使用简洁的祈使句。
- 不要在同一 PR 中混入无关格式化或重命名。

## 公开 API

- 只有需要被其他 Target 或 App 使用的符号才声明为 `public`。
- 优先使用语义明确的类型和命名空间，谨慎添加全局 Extension。
- 避免用大量布尔参数构造万能组件。
- 破坏性 API 修改必须说明迁移方式，并按语义化版本发布。

## 测试

- 新增格式化、数据转换和边界处理逻辑时必须补充单元测试。
- UI 组件至少应提供可编译的 Preview 或示例用法。
- 提交前运行相关测试；SwiftUI Target 应在 macOS/Xcode 环境验证。

## Pull Request 描述

PR 描述至少回答：

1. 改了什么？
2. 为什么属于公共 Package？
3. 哪些 App 将使用它？
4. 是否改变公开 API？
5. 使用什么方式验证？
