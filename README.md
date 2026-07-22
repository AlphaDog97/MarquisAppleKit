# MarquisAppleKit

`MarquisAppleKit` 是用于多个 Apple 平台 App 的私有 Swift Package，集中维护稳定、可复用的基础能力、设计令牌和 SwiftUI 基础组件。

> 这个仓库只承载跨 App 的通用能力。业务模型、业务流程和仅服务于单个 App 的组件应保留在对应 App 仓库中。

## 模块

### AppCore

与 UI 无关的基础能力：

- 通用错误模型 `AppError`
- 日期、数字和百分比格式化
- 统一日志封装 `AppLogger`
- Collection 安全下标
- iOS Haptic 封装

### AppDesignTokens

统一设计语言的最小令牌集合：

- 间距 `AppSpacing`
- 圆角 `AppRadius`
- 动效 `AppMotion`
- 字体层级 `AppTypography`
- 可注入的语义主题 `AppTheme`

### AppDesignComponents

由设计令牌组成的无业务 SwiftUI 组件：

- `PrimaryButton`
- `CardContainer`
- `LoadingStateView`
- `EmptyStateView`
- `SettingsRow`
- `MetricOverviewRow`

依赖方向固定为：

```text
AppDesignComponents
        ├── AppDesignTokens
        └── AppCore
```

具体 App 可以只引入需要的 Product。

## 系统要求

- Swift 6.0+
- iOS 17+
- macOS 14+
- Xcode 16+

最低系统版本应该以所有接入 App 的共同需求为准。仅支持较新系统的能力应放入独立 Target，而不是直接提高整个 Package 的最低版本。

## 安装

在 Xcode 中选择：

```text
File → Add Package Dependencies
```

输入仓库地址：

```text
https://github.com/AlphaDog97/MarquisAppleKit
```

然后选择需要的 Product：

```swift
import AppCore
import AppDesignTokens
import AppDesignComponents
```

生产项目应依赖语义化版本标签，不建议长期依赖 `main` 或其他可变分支。

## 快速使用

### 注入 App 主题

每个 App 保留自己的品牌主题：

```swift
import AppDesignTokens
import SwiftUI

private let myAppTheme = AppTheme(
    primary: .blue,
    onPrimary: .white,
    background: Color(uiColor: .systemBackground),
    surface: Color(uiColor: .secondarySystemBackground),
    textPrimary: .primary,
    textSecondary: .secondary,
    border: Color.primary.opacity(0.12),
    success: .green,
    warning: .orange,
    destructive: .red
)

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .appTheme(myAppTheme)
        }
    }
}
```

### 使用公共组件

```swift
import AppDesignComponents
import SwiftUI

struct ExampleView: View {
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            CardContainer {
                MetricOverviewRow(
                    title: "Recovery",
                    value: "82%",
                    subtitle: "Up 6% from yesterday"
                )
            }

            PrimaryButton("Continue") {
                // Handle action in the App layer.
            }
        }
        .padding(AppSpacing.large)
    }
}
```

### 格式化数据

```swift
import AppCore

let percentage = AppNumberFormatter.percentage(0.824)
let date = AppDateFormatter.string(from: .now)
```

## 字体策略

首版只提供系统字体令牌，避免把字体许可证和二进制资源默认传播到所有 App。

需要共享自定义字体时：

1. 先确认字体许可证允许在多个 App 中分发。
2. 把字体放到独立资源 Target，例如 `AppFontResources`。
3. 通过 `Bundle.module` 注册字体。
4. 使用字体的 PostScript Name，而不是假设文件名就是字体名。
5. 不要让不需要字体资源的 App 被迫下载该 Target。

## 抽取规则

代码进入本仓库前应满足以下条件：

1. 至少有两个 App 正在使用，或者已明确将在近期共同使用。
2. API 不包含单个 App 的业务术语。
3. 行为可以独立测试。
4. 公共层不依赖任何具体 App。
5. 抽取后比复制少量代码更容易维护。

以下内容通常不应进入公共包：

- SwiftData 或后端业务实体
- HealthKit 业务算法
- 视频分析、运动识别等 App 专属能力
- 只在单个 App 中出现的页面和业务组件
- 为兼容某一个页面而不断增加布尔参数的“万能组件”

## 版本管理

遵循语义化版本：

- `PATCH`：修复实现，不修改公开 API
- `MINOR`：新增向后兼容能力
- `MAJOR`：删除或修改已有公开 API

建议演进路径：

```text
0.1.0  首个可接入版本
0.x.y  快速验证 API
1.0.0  公共 API 稳定后发布
```

每个 App 应提交自己的 `Package.resolved`，确保 CI 与本地解析到一致依赖版本。

## 本地开发

```bash
swift test
```

由于 Package 包含 SwiftUI Target，完整构建和测试应在 macOS/Xcode 环境中运行。仓库的 GitHub Actions 会在 `macos-15` runner 上执行：

```bash
swift test
```

开发远程 Package 时，可以在 Xcode 中使用本地 Package 替换远程依赖，完成验证后再发布版本标签。

## 贡献流程

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。所有变更应通过分支和 Pull Request 提交，并说明：

- 为什么该能力属于公共层
- 哪些 App 会使用它
- 是否修改公开 API
- 如何验证行为
