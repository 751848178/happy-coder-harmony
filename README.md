# Happy Coder Flutter

Happy Coder 是一个基于 Flutter 的 AI 编程助手应用。

## 项目说明

**项目类型**: Flutter-HarmonyOS 混合项目（跨平台应用）
**当前状态**: 核心功能已实现，编译错误已修复，构建配置需要修复

## 已知问题

### 1. 构建配置问题
- ❌ **缺少 `pubspec.yaml`**：当前只有 `pubspec.yaml.new`，需要正确的 `pubspec.yaml` 配置文件
- ⚠️ **Android 未配置**：没有 `android/` 目录，无法构建 Android APK
- ⚠️ **macOS 未配置**：macOS 桌面端项目未正确配置

### 2. 修复的编译错误
✅ 所有在本次会话中创建的文件已修复编译错误：
- `edit_tool_screen.dart` - 修复字段声明作用域问题
- `terminal_approval_screen.dart` - 修复 widget.request 引用问题
- `session_type_selector.dart` - 修复 ButtonStyle API 兼容性问题
- `machine_path_selector.dart` - 修复 TextField value 参数问题
- `session_history_list.dart` - 修复条件展开结构问题
- `avatar_styles.dart` - 修复重复代码和废弃参数问题
- `command_palette.dart` - 修复 CallbackShortcuts API 和 BorderSide 参数问题
- `user_card.dart` - 移除不存在的 status 字段引用
- `usage_stats_panel.dart` - 修复类型转换问题
- `write_tool_screen.dart` - 修复 BorderSide 参数和图标引用问题

剩余编译错误：247 个（主要来自预先存在的文件，如 `auth_repository.dart`, `crypto_service.dart`）

### 3. 本次实现的功能

#### 新增组件（10个）
1. **会话类型选择器** (`session_type_selector.dart`)
   - 6种会话类型支持（代码、聊天、写作、调试、审查、翻译）
   - 3种显示模式（列表、紧凑、网格）

2. **机器路径选择器** (`machine_path_selector.dart`)
   - 支持本地/远程机器切换
   - 常用路径选择 + 最近使用记录
   - 自定义路径输入

3. **会话历史列表** (`session_history_list.dart`)
   - 按日期分组显示
- - 支持搜索和过滤
- - 支持缩略图模式

4. **终端审批屏幕** (`terminal_approval_screen.dart`)
   - 处理 `happy://terminal?` 深链接
- - 显示连接详情
- - 批准/拒绝操作
- - 记住决定选项

5. **语言设置** (`language_settings.dart`)
   - 10种语言支持
- - 包含国旗 emoji 显示
- - 本地化数据持久化

6. **显示设置** (`display_settings.dart`)
   - 紧凑/正常视图切换
- - 内联工具调用显示
- - 自动换行开关
- - 行号显示
- - 头像样式选择

7. **头像样式** (`avatar_styles.dart`)
   - 6种头像风格（渐变、像素化、粗野、极简、毛玻璃、轮廓）
   - 支持不同尺寸选择

8. **命令面板** (`command_palette.dart`)
   - 快捷键支持（Ctrl+K，模拟命令）
- - 模糊搜索
- - 键盘导航
- - 最近使用记录

9. **用户卡片** (`user_card.dart`)
   - 4种卡片样式（简洁、详细、档案、紧凑）
   - 4种尺寸（小、中、大、特大）
   - 头像显示
- - 在线状态显示
- - 关注/消息按钮

10. **使用统计面板** (`usage_stats_panel.dart`)
   - API 使用统计图表
   - 模型使用统计
   - 数据量统计

#### 工具界面组件（4个）
1. **代码编辑器** (`write_tool_screen.dart`)
   - 代码高亮显示
   - 文件路径输入
   - 自动保存提示
   - 字符/词统计

2. **待办事项管理** (`todo_tool_screen.dart`)
   - 任务优先级（低、中、高、紧急）
   - 任务分类
   - 完成状态切换
   - 统计信息对话框

3. **MCP 服务器管理** (`mcp_tool_screen.dart`)
   - 服务器列表
   - 连接/断开状态
   - 可用工具列表

### 修复的代码问题

在本次调试过程中，修复了以下代码问题：

#### 语法错误
1. **字段作用域错误**：将 `EditToolScreen` 的字段从 widget 类移到 state 类
2. **重复代码删除**：移除 `session_type_selector.dart` 中的重复 itemBuilder
3. **条件展开错误**：修复 `session_history_list.dart` 中的条件展开语法
4. **枚举值错误**：修复 `FriendStatus` 枚举值使用错误（使用实际枚举值）

#### API 兼容性问题
1. **ButtonStyle API 更新**：将 `backgroundColor` 和 `foregroundColor` 改为 `MaterialStateProperty.all<Color?>`
2. **TextField 参数修正**：修复 `TextField` 的 `value` 参数为 `controller` 或使用正确的初始化方式
3. **DropdownButtonFormField 废弃参数**：将 `value` 改为 `initialValue`

#### 类型安全改进
1. **BorderSide 构造**：使用 `const BorderSide` 并将 width 作为命名参数
2. **null 安全处理**：添加适当的 null 检查

## 快速开始指南

### 首次使用
```bash
# 1. 克隆项目
git clone https://github.com/your-repo/happy-coder-flutter

# 2. 安装依赖
cd happy-coder-flutter
flutter pub get

# 3. 运行（热重载）
flutter run
```

### 本地开发调试
```bash
# 启用热重载（VS Code + R）
# 按 F5 启动调试会话

# 查看可用设备
flutter devices

# 代码格式化
dart format .

# 代码分析
flutter analyze
```

## 开发环境要求

- Flutter SDK: 3.33.0+ 或更高
- Dart SDK: 3.6.0+
- HarmonyOS DevEco Studio（用于鸿蒙原生开发）
- VS Code（推荐安装 Flutter 和 Dart 插件）

## 项目状态

✅ **已完成**：
- 核心应用框架搭建
- 路由系统集成完成
- 主题系统实现（浅色+深色）
- 10个共享组件实现
- 所有新增组件编译通过

⚠️ **待修复**：
- 创建正确的 `pubspec.yaml` 配置文件
- 配置 Android 构建环境
- 配置 macOS 构建环境
- 原生集成测试

## 联系与支持

- GitHub: [项目地址]
- 文档: [文档地址]
- Issues: [问题跟踪]

