# 前端设计说明 — Karis Review

## 1. 设计立场

Karis Review 的产品定位是“极简、专注的间隔重复闪卡复习”。这个界面最重要的事只有一件：让用户知道今天要复习什么，以及一次评分之后，这张卡下次什么时候回来。

因此本设计的极简不是删掉信息，而是把信息重新排序：

- 首页只突出“今日待复习”这一件事。
- 复习页把“翻面”和“评分”放在中心，去掉干扰。
- 每个界面都保留一条真实的数据线索：卡片的间隔阶段。
- 统计页呈现趋势和阶段分布，但不堆砌图表。

视觉上的核心风险选择是“记忆刻度”：把排期算法中的 0、1、2、4、7、15、30、90、180 天真实画成一条九段刻度尺。它既是装饰，也是信息，不是常见的 01/02/03 编号装饰。

## 2. 视觉语言

### 2.1 主题：记忆刻度

整套界面像一张被整理过的学习档案：浅灰绿纸面、墨色文字、细发丝线，以及克制使用的青、朱、金三色。青代表熟悉和稳定，朱代表忘记和需要重新建立，金代表模糊和重学。

| Token | 色值 | 用途 |
|------|------|------|
| 雾纸 | `#EEF2EE` | 页面背景 |
| 纸面 | `#F9FBF7` | 卡片、面板、输入框表面 |
| 墨 | `#202B27` | 主文字、主按钮 |
| 石 | `#66716B` | 次级文字、说明 |
| 青 | `#2F6B5C` | 熟悉、完成、主强调 |
| 朱 | `#C45B43` | 忘记、危险操作 |
| 金 | `#B98A2F` | 模糊、重学 |
| 发丝线 | `#DCE3DB` | 边框、分隔线 |

配色没有采用单一蓝色 seed 或常见的暖米色模板，而是用带一点绿的灰纸色做底，让数据与状态色有明确的层级。

暗色模式（`ThemeMode.system` 跟随系统）采用「纸感暗色」而非纯黑：背景带绿灰、文字用暖墨白，语义色提亮一档保证暗底对比度。

| Token | 亮色 | 暗色 | 用途 |
|------|------|------|------|
| 雾纸 / 夜纸 | `#EEF2EE` | `#131A16` | 页面背景 |
| 纸面 / 夜面 | `#F9FBF7` | `#1B231E` | 卡片、面板、输入框表面 |
| 墨 / 夜墨 | `#202B27` | `#E8EFE9` | 主文字、主按钮 |
| 石 / 夜石 | `#66716B` | `#96A49B` | 次级文字、说明 |
| 青 / 夜青 | `#2F6B5C` | `#57A08B` | 熟悉、完成、主强调 |
| 朱 / 夜朱 | `#C45B43` | `#D9826B` | 忘记、危险操作 |
| 金 / 夜金 | `#B98A2F` | `#D6AC56` | 模糊、重学 |
| 发丝线 / 夜线 | `#DCE3DB` | `#2C3A32` | 边框、分隔线 |

实现上颜色统一收敛为 `KarisColors` ThemeExtension，页面通过 `context.karisColors` 访问，禁止直接引用亮色常量；soft 色（jadeSoft/amberSoft/cinnabarSoft）暗色下使用色相叠加的实色值。

记忆刻度（九段刻度尺）的渲染规则：分布模式下，有卡片的阶段按占比在青（`#2F6B5C`）色系内由浅到深渐变——占比越高颜色越深，无卡片的阶段保持发丝线灰；长度与颜色双通道编码，一眼可读各阶段存量。今日页刻度的数据口径是“今日任务”：今日到期分布 + 待学新卡并入 stage 0（新卡 `next_review_date` 为空、天然不在到期分布内），与首页“待复习 / 待学习”文案一致。

### 2.2 字体

| 角色 | 字体 | 说明 |
|------|------|------|
| 展示 | Noto Serif SC / Songti SC | 页面标题、卡片问题与答案；低字重、大行高，克制使用 |
| 正文 | Noto Sans SC / PingFang SC | 界面正文、按钮、说明 |
| 数据 | IBM Plex Mono / Consolas | 日期、数量、阶段、间隔天数 |

数字和日期统一使用等宽字体，保证进度、队列、统计在变化时不会抖动。

### 2.3 形状与阴影

- 卡片、按钮、输入框圆角统一为 8px。
- 界面内不使用大面积阴影，卡片与列表靠 1px 发丝线分层。
- 设备外框和复习卡翻面时保留柔和阴影，用于建立“实物感”，不用于普通内容层级。

## 3. 信息架构

应用包含 5 个主要视图：

| 视图 | 主要职责 | 关键信息 |
|------|---------|---------|
| 今日 | 每日入口 | 今日待复习、已复习、记忆刻度 |
| 卡片 | 卡组内卡片管理 | 卡片内容、阶段、下次复习、新建/编辑 |
| 复习 | 单卡翻面与评分 | 进度、问题/答案、连续熟悉、评分后间隔 |
| 统计 | 学习概览 | 总卡片、待复习、今日复习、趋势、阶段分布 |
| 设置 | 账号、刷新时间与数据 | 邮箱、每日刷新时间、导出/导入 |

导航层级：

- 手机：底部四个一级入口：今日、卡组、统计、设置。
- 平板：顶部悬浮药丸导航，玻璃置顶；内容区保留相同一级入口，卡片页作为“今日 → 卡组”的二级页面。
- 复习不再占一级入口：首页“开始”按钮进入二级选择界面，先切换学习/复习，再选择全部卡组或单个卡组，左上角返回，不显示导航栏。

## 4. 布局与自适应

### 4.1 手机：390 × 844

- 底部导航为悬浮药丸，使用低模糊玻璃（药丸 18px、底部渐变遮罩 10px），遮罩从上缘渐变淡出；内容区底部预留 132px，避免导航遮蔽。
- 二级页面不显示底部导航，使用左上角返回按钮回到上级。
- 首页结构：日期标题 → 今日待复习 → 记忆刻度；“开始”按钮靠右并垂直居中，点击后进入学习/复习选择界面。
- 复习页：进度条固定在上方，卡片占满剩余空间，评分条固定在底部；翻面后显示忘记/模糊/熟悉，答案面可再次点击回到问题面。
- 快捷导入页内置 JSON 格式说明与示例复制入口，输入区和解析按钮之间展示格式要点。

### 4.2 平板：940 × 680

- 顶部悬浮药丸导航，使用低模糊渐变玻璃，从导航上缘向下自然淡出；内容区顶部预留 132px。
- 首页与移动端一致：日期标题 → 今日待复习 → 记忆刻度，不重复展示卡组列表。
- 复习页变为双栏：左侧今日队列，右侧当前卡片与评分。
- 统计页变为双栏：左侧指标与趋势，右侧阶段分布。
- 设置页变为双栏：账号/复习设置与数据管理并行。

两种模式共享同一套数据和交互逻辑，只通过断点改变信息密度，不拆分页面。

## 5. 动效设计

动效服务于“回忆”这个动作，不制造氛围。

所有时长/缓动收敛为统一 Motion Tokens（`shared/utils/motion.dart` 的 `KarisMotion`），新增动效一律复用，禁止散落时间常量：

| Token | 时长 | 用途 |
|------|------|------|
| press | 120ms | 按钮/评分按压收缩（scale 0.94-0.97） |
| feedback | 180ms | Toast / Banner / 状态 chip |
| cardSwitch | 240ms | 评分后换卡 |
| page | 260ms | 路由切换（reverse 220ms） |
| flip | 480ms | 3D 翻面 |
| grow | 600ms | 图表生长、完成进度环、空状态入场 |
| staggerStep | 40ms/项 | 列表交错入场（`KarisEntrance`） |
| shimmer | 1200ms 循环 | 骨架屏流光（`KarisSkeletonGroup`） |

- 按钮使用动作语言：“开始”“开始复习”“开始学习”“保存”“导出数据”“新建卡片”。
|------|------|------|------|
| 卡片翻面 | 480ms | 慢入慢出 | 模拟真实卡片，强化“思考后查看答案” |
| 评分反馈 | 240ms | 快出 | 当前卡退出，下一张进入 |
| 页面切换 | 260ms | 淡入 + 6px 位移 | 保持方向感 |
| 设备切换 | 560ms | 弹性缓动 | 手机到平板的形态变化 |
| Toast 提示 | 180ms | 淡入 | 确认评分结果 |
| 列表入场 | 40ms/项 交错 | 淡入 + 8px 上移 | 卡组/卡片列表首屏递进 |
| 骨架屏 | 1200ms 流光 | shimmer | 首页/列表加载态，替代内联 spinner |
| 图表生长 | 600ms | 从左到右揭示 | 统计趋势线、阶段分布柱 |
| 复习完成 | 600ms | 弹性放大 | 完成图标收尾，克制不浮夸 |

桌面 Web 复习页支持键盘快捷键：空格翻面，`1`/`2`/`3` 分别评分忘记/模糊/熟悉（评分按钮上显示对应数字提示）。

`prefers-reduced-motion` 开启时，所有动画退化为瞬时切换，不丢失交互状态。

## 6. 文案与可访问性

- 按钮使用动作语言：“开始复习”“保存”“导出数据”“新建卡片”。
- 复习评分直接使用业务词汇：忘记、模糊、熟悉，并在评分按钮下显示下次间隔，例如“重学”“4 天”“7 天”。
- 触控目标不小于 44px。
- 所有交互控件保留可见键盘焦点。
- 文案与背景对比度按 WCAG AA 设计；次级文字只用于辅助信息。
- 空状态使用方向性文案，例如“还没有卡组，创建第一个卡组开始复习”，不把失败写成情绪化表达。
- 破坏性操作（如撤销导入会删除刚导入的卡片）用常驻 Banner 说明后果、不自动消失，执行前弹确认对话框二次确认，避免误触。

## 7. Flutter 落地映射

### 7.1 主题令牌

`frontend/lib/app/theme.dart` 中的 `KarisColors` 已实现为 `ThemeExtension<KarisColors>`，提供 `light` / `dark` 两套实例，随 `themeMode: ThemeMode.system` 自动切换：

```dart
// 页面访问（避免引用扩散）：
final colors = context.karisColors; // KarisColorsContext extension
```

- 亮色值：`ink #202B27`、`stone #66716B`、`jade #2F6B5C`、`cinnabar #C45B43`、`amber #B98A2F`、`paper #EEF2EE`、`surface #F9FBF7`、`hairline #DCE3DB`。
- 暗色值：`ink #E8EFE9`、`stone #96A49B`、`jade #57A08B`、`cinnabar #D9826B`、`amber #D6AC56`、`paper #131A16`、`surface #1B231E`、`hairline #2C3A32`。
- soft 色暗色值（色相叠加实色，非 alpha）：`jadeSoft #22312A`、`amberSoft #332B1C`、`cinnabarSoft #362220`。

`ColorScheme` 的 `primary` 使用青，`error` 使用朱；`FAMILIAR / VAGUE / FORGET` 分别映射到青、金、朱。状态栏/导航栏样式由 `app.dart` 的 `AnnotatedRegion` 按主题亮度自动适配。

### 7.2 组件规范与拆分

使用规范（硬性约定，新增功能必须遵守）：

- 用户反馈一律走 `showKarisFeedback`（tone: success/warning/error），禁止裸用 `SnackBar`；导入撤销等需常驻的反馈用 `MaterialBanner` 并明示后果。
- 页面加载态统一使用 `LoadingWidget` / `AppErrorWidget` / `EmptyState` 或骨架屏（`KarisSkeletonGroup`），禁止散落内联 `CircularProgressIndicator`（按钮内提交中状态除外）。
- 所有动画时长/缓动取自 `KarisMotion`，禁止散落时间常量；动效必须经过 `reducedDuration` 支持 reduced-motion 降级。

组件清单（均在 `frontend/lib/` 下）：

- `StageRuler` / `MiniStageRuler`（`shared/widgets/stage_ruler.dart`）：九段记忆刻度；分布模式按占比做青系渐变（`Color.lerp(jadeSoft, jade, ratio)`），无卡为发丝线灰，为有卡阶段提供“新卡 · N 张”无障碍标签。
- `KarisScrollBehavior`（`shared/widgets/karis_scroll_behavior.dart`）：全局滚动行为，桌面/Web 纵向滚动常驻可拖拽滚动条（`minThumbLength: 48` 兜底）；触屏（含手机浏览器 Web）拖动时叠加显示滚动位置指示，避免 Flutter Web 触屏无原生滚动条导致完全不可见；水平滚动不显示。
- `ReviewFlipCard` / `ReviewCardFrame`（`review/widgets/review_flip_card.dart`）：3D 翻面，支持从答案面点击回到问题面，reduced-motion 降级。
- `AdaptiveAppScaffold` / `KarisIconButton` / `KarisPrimaryButton` / `KarisSecondaryButton`（`shared/widgets/adaptive_scaffold.dart`）：断点自适应浮岛药丸导航与统一按钮。
- `MetricTile`（`shared/widgets/metric_tile.dart`）：统一统计数字样式，固定高度、`tabularFigures()` 防抖动。
- `SettingsActionTile`（`shared/widgets/settings_action_tile.dart`）：统一设置行与数据操作入口。
- `SectionHeader` / `Kicker` / `EmptyState`（`shared/widgets/section_widgets.dart`）：统一小节标题与空状态（空状态带入场动画）。
- `KarisFeedbackBar` / `showKarisFeedback`（`shared/widgets/app_feedback.dart`）：统一 Toast 反馈。
- `LoadingWidget` / `AppErrorWidget`（`shared/widgets/loading_widget.dart` / `error_widget.dart`）：统一加载与错误态。
- `KarisEntrance` / `KarisPressable` / `KarisSkeleton` / `KarisSkeletonGroup`（`shared/widgets/entrance.dart`）：列表交错入场、按压反馈、shimmer 骨架屏。

### 7.3 断点策略

建议在 `Scaffold` 外层使用 `LayoutBuilder`：

- 宽度小于 600px：手机布局，悬浮药丸底部导航。
- 宽度大于等于 600px：平板布局，顶部悬浮药丸导航，内容按双栏排布。
- 复习页不因为设备变大而改变核心流程，只增加队列侧栏。

### 7.4 实现文件索引

| 关注点 | 文件 |
|------|------|
| 颜色 tokens / 亮暗主题 | `frontend/lib/app/theme.dart`（`KarisColors` ThemeExtension、`appTheme` / `appDarkTheme`） |
| 主题挂载 / 系统栏 | `frontend/lib/app/app.dart`（darkTheme、themeMode.system、AnnotatedRegion） |
| 路由过渡 | `frontend/lib/app/router.dart`（`_fadeSlidePage`，reduced-motion 感知） |
| 动效 tokens | `frontend/lib/shared/utils/motion.dart`（`KarisMotion`、`reducedDuration`） |
| 动效组件 | `frontend/lib/shared/widgets/entrance.dart`（`KarisEntrance` / `KarisPressable` / 骨架屏） |
| 浮岛导航毛玻璃 | `frontend/lib/shared/widgets/adaptive_scaffold.dart` |
| 3D 翻卡 | `frontend/lib/review/widgets/review_flip_card.dart` |
| 复习页（换卡 / 评分 / 快捷键 / 完成庆祝） | `frontend/lib/review/pages/review_page.dart` |
| 开始流程 | `frontend/lib/review/pages/start_flow_page.dart` |
| 阶段尺 | `frontend/lib/shared/widgets/stage_ruler.dart` |
| 趋势图 / 柱状图（生长 + tooltip） | `frontend/lib/stats/pages/stats_page.dart` |
| 今日首页（骨架屏） | `frontend/lib/home/pages/home_page.dart` |
| 卡组列表（骨架屏 + 列表入场） | `frontend/lib/deck/pages/deck_list_page.dart` |
| 反馈 / 加载 / 空态封装 | `frontend/lib/shared/widgets/app_feedback.dart`、`loading_widget.dart`、`error_widget.dart`、`section_widgets.dart` |

## 8. 需求覆盖

| 需求 | 对应设计 |
|------|---------|
| UR-16 学习模式 | 复习页支持学习队列，卡片显示新卡状态 |
| UR-17 复习模式 | 首页待复习入口与复习页队列 |
| UR-18 先看正面再翻面 | 3D 翻卡交互 |
| UR-19 忘记/模糊/熟悉 | 三个评分按钮及下次间隔提示 |
| UR-20 自动安排下次复习 | 记忆刻度与评分后间隔反馈 |
| UR-21 查看今日待复习数量 | 首页今日待复习 |
| UR-22 学习统计概览 | 统计页指标 |
| UR-23 每个卡组学习进度 | 卡组列表与卡片页阶段信息 |
| UR-24 复习趋势 | 统计页趋势图 |
| UQ-01 简洁清爽 | 单焦点首页与细线分层 |
| UQ-02 移动/桌面一致 | 同一数据模型，手机/平板自适应 |
| UQ-04 单手操作 | 手机悬浮药丸导航与独立编辑/导入页面，正反面分段切换 |

## 9. 交付物

- `docs/frontend-design/index.html`：可直接打开的交互原型入口，默认显示手机屏幕，可切换为平板屏幕。
- `docs/frontend-design/styles.css`：原型样式，包含手机/平板断点、悬浮导航与动效。
- `docs/frontend-design/app.js`：原型交互逻辑，包含页面切换、翻卡评分、弹层和设备切换。
- `docs/frontend-design.md`：本设计说明。
- `docs/frontend-design/screenshots/mobile/`：Flutter Web 手机布局页面与组件截图（15 张）。
- `docs/frontend-design/screenshots/tablet/`：Flutter Web 平板布局页面与组件截图（15 张）。
- `tools/screenshots/`：可重复运行的 Playwright 截图工具，自动注册演示账号并生成手机、平板各 15 张截图。
- `docs/README.md`：文档索引新增本设计说明入口。

## 10. 变更记录（2026-08-06）

三个迭代落地完成，验证：`flutter analyze` 无问题、`flutter test` 185 个全部通过。

**迭代 1 · 组件一致性**
- 全库裸用 `SnackBar` 替换为 `showKarisFeedback`（tone 语义化）；独立内联 spinner 统一为 `LoadingWidget`（按钮内提交中状态保留）。
- shimmer 依赖启用；`prefers-reduced-motion` 全局降级（翻卡 / 换卡 / 路由 / 隐式动画全部接入，设计文档第 5 节承诺兑现）。

**迭代 2 · 暗色模式**
- `KarisColors` 从静态常量迁移为 `ThemeExtension`（亮 / 暗两套），页面统一 `context.karisColors` 访问，全库无静态引用残留。
- `MaterialApp` 挂载 `darkTheme` + `themeMode: ThemeMode.system`；系统栏样式由 `AnnotatedRegion` 自动适配。
- 毛玻璃导航、翻卡阴影、评分条、开始页 segmented 等暗色视觉逐一适配。

**迭代 3 · 动效体系**
- 新增 Motion Tokens（见第 5 节）与 `KarisEntrance` / `KarisPressable` / `KarisSkeleton` / `KarisSkeletonGroup` 组件。
- 列表交错入场（卡组 / 卡片 / 开始页 / 空状态）、评分按钮按压反馈、首页与卡组列表骨架屏、趋势图生长动画与点击 tooltip、复习完成弹性庆祝。
- 复习页键盘快捷键：空格翻面，`1` / `2` / `3` 评分（见第 5 节）。

**测试适配**：`test/widgets_test.dart` 1 处断言随评分按钮组件结构调整（`InkWell` → `KarisPressable`），断言意图不变。

## 11. 后续可选项

- 字体资产打包：Web 端 Noto Serif SC 子集，保证跨设备标题渲染一致。
- 设置页增加「跟随系统 / 亮色 / 暗色」手动主题切换。
- 复习完成页增加进度环（当前为弹性放大图标收尾）。
- 断点切换过渡：手机 ↔ 平板形态变化增加 560ms 弹性动效（当前为瞬时切换）。
- 新用户首启引导：今日首页无数据时叠加可关闭的轻提示，介绍记忆刻度读法。
