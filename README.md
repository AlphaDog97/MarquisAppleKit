# MarquisAppleKit

`MarquisAppleKit` 是用于多个 Apple 平台 App 的私有 Swift Package，集中维护稳定、可复用的基础能力、设计令牌和 SwiftUI 基础组件。

> 这个仓库只承载跨 App 的通用能力。业务模型、业务流程、持久化策略和仅服务于单个 App 的组件应保留在对应 App 仓库中。

## 模块

### AppCore

与 UI 无关的基础能力：

- 通用错误模型 `AppError`
- 日期、数字和百分比格式化
- 统一日志封装 `AppLogger`
- Collection 安全下标
- 跨平台安全的 Haptic 封装

### AppDesignTokens

统一设计语言的基础令牌：

- 间距 `AppSpacing`
- 圆角 `AppRadius`
- 动效 `AppMotion`
- App 语义字体角色 `AppTypographyRole`
- Widget 与 Live Activity 字体角色 `AppWidgetTypographyRole`
- 字体别名 `AppTypography`
- 可注入的语义主题 `AppTheme`

### AppDesignComponents

由设计令牌组成的无业务 SwiftUI 组件：

- `PrimaryButton`
- `CardContainer`
- `LoadingStateView`
- `EmptyStateView`
- `SettingsRow`
- `MetricOverviewRow`
- Coach Mark 聚光灯引导
- Action Prompt 统一确认框

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

### 注入 App 主题和字体作用域

每个 App 保留自己的品牌主题，并在场景根节点应用一次字体作用域：

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
                .appTypographyScope()
        }
    }
}
```

`appTypographyScope()` 为尚未迁移的旧视图提供统一圆体基线。新代码仍应显式选择语义角色。

### 使用语义字体

```swift
VStack(alignment: .leading, spacing: AppSpacing.small) {
    Text("Weekly Progress")
        .appTextStyle(.eyebrow)

    Text("Keep moving forward")
        .appTextStyle(.heroTitle)

    Text("You completed 18 of 24 planned tasks.")
        .appTextStyle(.body)

    Text("75%")
        .appTextStyle(.metricLarge)
}
```

当某个 API 只接受 `Font` 时，使用字体别名：

```swift
Text("18 days")
    .font(AppTypography.metricCompact)
```

优先使用 `appTextStyle(_:)`，因为它会同时应用字体、字距和行距。

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

## Coach Mark 聚光灯引导

Coach Mark 源自 GoalMaster `vibe` 分支的页面级引导体系。公共包只负责目标注册、聚光灯、引导卡片和步骤推进；是否展示、版本号、完成状态和持久化由具体 App 决定。

### 定义流程

```swift
import AppDesignComponents
import SwiftUI

private enum HomeCoachTarget {
    static let create: CoachMarkTargetID = "home.create"
    static let filter: CoachMarkTargetID = "home.filter"
}

private let homeCoachFlow = CoachMarkFlow(
    id: "home.v1",
    steps: [
        CoachMarkStep(
            id: "create",
            targetID: HomeCoachTarget.create,
            title: "Create something",
            message: "Use this button to create your first item.",
            iconSystemName: "plus.circle.fill",
            preferredPlacement: .bottom
        ),
        CoachMarkStep(
            id: "filter",
            targetID: HomeCoachTarget.filter,
            title: "Narrow the list",
            message: "Filters help you focus on the items that matter now.",
            iconSystemName: "line.3.horizontal.decrease.circle",
            preferredPlacement: .top
        )
    ]
)
```

### 注册目标并展示

```swift
struct HomeView: View {
    @State private var coachMarkIndex: Int? = 0

    var body: some View {
        VStack {
            Button("Create") { }
                .coachMarkTarget(HomeCoachTarget.create)

            Button("Filter") { }
                .coachMarkTarget(HomeCoachTarget.filter)
        }
        .coachMarkFlow(
            homeCoachFlow,
            currentStepIndex: $coachMarkIndex,
            onSkip: {
                markHomeCoachFlowCompleted()
            },
            onCompletion: {
                markHomeCoachFlowCompleted()
            }
        )
    }

    private func markHomeCoachFlowCompleted() {
        // Persist completion in the App layer.
    }
}
```

注意事项：

- `currentStepIndex == nil` 时不会展示引导。
- `CoachMarkTargetID` 应使用稳定字符串，避免跟随页面文案变化。
- 默认按钮文案为 `Skip`、`Next` 和 `Got it`，可通过 `CoachMarkLabels` 注入 App 自己的本地化 Key。
- 当前步骤目标未注册时不会绘制 Overlay；这通常说明页面状态与流程配置不匹配。
- 公共包不使用 `UserDefaults`、SwiftData 或 iCloud 保存完成状态。

## Action Prompt 统一确认框

Action Prompt 用于替代分散的自定义确认弹层，并保持跨 App 一致的视觉、Dynamic Type、VoiceOver 焦点、Reduce Motion 和 Haptic 行为。

支持的样式：

```text
destructive
warning
info
completion
replacement
```

每个 Prompt 必须包含 1–3 个操作，并且最多只能有一个 `.cancel` 操作。

```swift
struct AccountView: View {
    @State private var prompt: ActionPromptState?

    var body: some View {
        Button("Delete account") {
            prompt = ActionPromptState(
                style: .destructive,
                title: "Delete account?",
                message: "This action cannot be undone.",
                detail: "Your synced data will also be removed.",
                actions: [
                    ActionPromptAction("Cancel", role: .cancel),
                    ActionPromptAction(
                        "Delete",
                        role: .destructive
                    ) {
                        deleteAccount()
                    }
                ]
            )
        }
        .actionPrompt($prompt)
    }

    private func deleteAccount() {
        // Perform the business operation in the App layer.
    }
}
```

`ActionPromptState` 支持：

- 默认或自定义 SF Symbol
- 基于 `AppTheme` 的默认状态颜色
- 单独传入 `accent`
- 主操作、次操作、破坏性操作和取消操作
- 可选背景点击关闭
- iPhone/iPad 底部展示，macOS 与 Mac Catalyst 居中展示

Prompt 的业务副作用只存在于 `ActionPromptAction` 闭包中，公共组件不访问业务模型。

### 格式化数据

```swift
import AppCore

let percentage = AppNumberFormatter.percentage(0.824)
let date = AppDateFormatter.string(from: .now)
```

## 语义字体体系

这套字体体系源自 GoalMaster 的语义字体实践，并被改造成不包含具体 App 命名的公共 API。

### 设计原则

- 所有普通文本均基于系统 Text Style，自动参与 Dynamic Type。
- 高强调标题、控件、徽章和指标使用 SF Rounded。
- 正文与辅助说明使用默认 SF Pro 设计，保证长文本可读性。
- 数值指标使用 monospaced digits，实时变化时不会造成布局跳动。
- 字体负责表达信息层级，颜色继续由 `AppTheme` 表达品牌和状态。
- 除 SF Symbol 几何尺寸外，业务文本不使用固定字号。

### App 角色

| Role | 用途 |
| --- | --- |
| `display` | Onboarding 宣言或少量活动型大标题 |
| `pageTitle` | 页面主标题 |
| `navigationTitle` | 内联工具栏标题 |
| `heroTitle` | Hero 卡片中的主信息 |
| `eyebrow` | 标题上方的模块或分类短标签 |
| `sectionTitle` | 页面内主要分区标题 |
| `cardTitle` | 卡片、目标、任务和事件名称 |
| `body` | 正文、编辑器内容和主要说明 |
| `supporting` | 副标题与补充解释 |
| `metadata` | 日期、单位和进度上下文 |
| `caption` | 三级说明和高密度辅助信息 |
| `control` | 按钮、分段控件和紧凑操作 |
| `badge` | 状态 Chip 与紧凑标签 |
| `metricLarge` | Dashboard 主指标 |
| `metric` | 卡片级指标 |
| `metricCompact` | 倒计时和高密度数字 |

### Widget 与 Live Activity 角色

WidgetKit 和 ActivityKit 使用更紧凑的 `AppWidgetTypographyRole`：

| Role | 用途 |
| --- | --- |
| `eyebrow` | 模块和状态短标签 |
| `title` | Widget 或 Live Activity 标题 |
| `body` | 主要紧凑文本 |
| `supporting` | 副标题、任务名和日期 |
| `caption` | 三级高密度信息 |
| `control` | 交互式 Widget 控件标签 |
| `metricLarge` | 锁屏主数值 |
| `metric` | Widget 或展开灵动岛数值 |
| `metricCompact` | Timer、计数和紧凑灵动岛数值 |

使用方式：

```swift
struct ExampleWidgetContent: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("TODAY")
                .appWidgetTextStyle(.eyebrow)

            Text("7 tasks")
                .appWidgetTextStyle(.metric)
        }
        .appWidgetTypographyScope()
    }
}
```

`appWidgetTypographyScope()` 应应用在每个 Widget 或 Live Activity 内容根节点。显式角色仍负责具体层级和数值样式。

### 迁移建议

把直接写在 Feature 中的字体：

```swift
Text(title)
    .font(.system(.headline, design: .rounded, weight: .semibold))
```

替换为：

```swift
Text(title)
    .appTextStyle(.cardTitle)
```

迁移不需要一次完成。先在根节点添加字体作用域，再在新代码或被修改的旧代码中逐步使用语义角色。

## 自定义字体策略

当前语义体系只使用系统字体，不引入字体文件、许可证风险或额外包体积。

需要共享自定义字体时：

1. 先确认字体许可证允许在多个 App 中分发。
2. 把字体放到独立资源 Target，例如 `AppFontResources`。
3. 通过 `Bundle.module` 注册字体。
4. 使用字体的 PostScript Name，而不是假设文件名就是字体名。
5. 不要让不需要字体资源的 App 被迫下载该 Target。
6. 自定义字体仍应映射到现有语义角色，而不是在 Feature 中直接指定字号。

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

由于 Package 包含 SwiftUI Target，完整构建和测试应在 macOS/Xcode 环境中运行。仓库的 GitHub Actions 会在 macOS runner 上执行同一命令。

开发远程 Package 时，可以在 Xcode 中使用本地 Package 替换远程依赖，完成验证后再发布版本标签。

## 贡献流程

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。所有变更应通过分支和 Pull Request 提交，并说明：

- 为什么该能力属于公共层
- 哪些 App 会使用它
- 是否修改公开 API
- 如何验证行为
