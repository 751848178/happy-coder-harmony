import 'dependencies.dart';
import '../../../storage/domain/storage_models.dart' as storage_models;

/// ============================================================================
/// 会话详情页（Session Detail Screen）
/// ============================================================================
/// 
/// 这是应用最核心、最复杂的页面，负责显示和管理单个会话的所有内容
/// 
/// 【主要功能】
/// 1. 消息列表显示 - 展示用户和 AI 的对话历史
/// 2. 消息发送 - 用户输入并发送新消息
/// 3. 实时更新 - 通过 WebSocket 接收 AI 的回复
/// 4. 消息加载 - 支持分页加载历史消息（向上滚动加载更早的消息）
/// 5. 工具调用 - 显示和管理 AI 使用的工具（如代码执行、文件操作）
/// 6. 权限管理 - 处理工具调用的权限请求和审批
/// 7. 滚动控制 - 智能滚动到最新消息、跳转到特定位置
/// 8. 队列管理 - 管理待发送的消息队列
/// 
/// 【架构设计】
/// 采用 part/part of 模式将大型页面拆分成多个文件：
/// - state/ - 状态管理相关代码
/// - view/ - UI 渲染相关代码
/// - message/ - 消息处理相关代码
/// - presenter/ - 数据展示逻辑
/// - viewport/ - 视口和滚动控制
/// - command/ - 命令面板相关
/// - controllers/ - 控制器（协调多个功能）
/// - widgets/ - 可复用的小组件
/// 
/// 【性能优化】
/// 1. 使用 ValueNotifier 避免全屏重建
/// 2. 消息列表使用虚拟滚动（只渲染可见区域）
/// 3. 分页加载历史消息（不一次性加载所有消息）
/// 4. 使用 part 文件拆分代码（编译时合并，运行时是一个类）
/// 
/// 【学习要点】
/// - part/part of 是 Dart 的代码组织方式，允许将一个类拆分到多个文件
/// - ValueNotifier 用于细粒度的状态管理，避免不必要的重建
/// - ConsumerStatefulWidget 结合了 StatefulWidget 和 Riverpod
/// - SingleTickerProviderStateMixin 提供动画控制器
/// - WidgetsBindingObserver 监听应用生命周期（前台/后台切换）
/// ============================================================================

// 【part 文件列表】
// 以下文件都是 _SessionScreenState 类的一部分
// 它们通过 extension 或 part of 的方式扩展主类的功能

// 命令相关
part 'command/logic.dart';              // 命令逻辑
part 'command/panels.dart';             // 命令面板 UI
part 'command/template_editor.dart';    // 模板编辑器

// 控制器
part 'controllers/command_controller.dart';  // 命令控制器
part 'controllers/load_coordinator.dart';    // 加载协调器
part 'controllers/load_session_data.dart';   // 会话数据加载

// 消息相关
part 'message/actions.dart';            // 消息操作（复制、删除等）
part 'message/bubble.dart';             // 消息气泡
part 'message/forward.dart';            // 消息转发
part 'message/turn_group.dart';         // 对话轮次分组
part 'message/view_state.dart';         // 消息视图状态

// 数据展示器
part 'presenter/body_flat_items.dart';  // 扁平化消息列表
part 'presenter/body_grouping.dart';    // 消息分组逻辑
part 'presenter/body_metrics.dart';     // 性能指标
part 'presenter/body_effects.dart';     // 副作用处理
part 'presenter/body_presenter.dart';   // 主展示器
part 'presenter/body_resolve.dart';     // 数据解析

// 状态管理
part 'state/actions.dart';              // 用户操作
part 'state/appbar.dart';               // 顶部栏
part 'state/build.dart';                // 构建逻辑
part 'state/clone.dart';                // 会话克隆
part 'state/constants.dart';            // 常量定义
part 'state/debugging.dart';            // 调试工具
part 'state/load.dart';                 // 数据加载
part 'state/message_interactions.dart'; // 消息交互
part 'state/message_sync.dart';         // 消息同步
part 'state/queue.dart';                // 消息队列
part 'state/queue_management.dart';     // 队列管理
part 'state/refresh.dart';              // 刷新逻辑
part 'state/refresh_anchor.dart';       // 刷新锚点
part 'state/refresh_newer.dart';        // 加载更新消息
part 'state/refresh_older.dart';        // 加载历史消息
part 'state/refresh_session_sync.dart'; // 会话同步
part 'state/refreshing.dart';           // 刷新状态
part 'state/screen_awake.dart';         // 屏幕常亮
part 'state/screen_state.dart';         // 屏幕状态（核心）
part 'state/screen_widget.dart';        // 屏幕 Widget
part 'state/scroll.dart';               // 滚动控制
part 'state/selection.dart';            // 选择状态
part 'state/socket.dart';               // Socket 连接
part 'state/sticky_prompt.dart';        // 置顶提示
part 'state/tool_actions.dart';         // 工具操作
part 'state/turns.dart';                // 对话轮次

// 视图组件
part 'view/controls.dart';              // 控制按钮
part 'view/indicators.dart';            // 指示器
part 'view/input.dart';                 // 输入框
part 'view/message_anchors.dart';       // 消息锚点
part 'view/message_file_handler.dart';  // 文件处理
part 'view/messages.dart';              // 消息列表（主视图）
part 'view/message_list.dart';          // 消息列表实现
part 'view/message_scroll.dart';        // 消息滚动
part 'view/message_stage.dart';         // 消息舞台
part 'view/metadata.dart';              // 元数据显示
part 'view/overview.dart';              // 概览面板
part 'view/queue_panel.dart';           // 队列面板
part 'view/sticky_indicators.dart';     // 置顶指示器
part 'view/thinking_indicators.dart';   // 思考指示器

// 视口控制
part 'viewport/edge_autoload.dart';     // 边缘自动加载
part 'viewport/scroll_boundaries.dart'; // 滚动边界
part 'viewport/scroll_commands.dart';   // 滚动命令
part 'viewport/state_restore.dart';     // 状态恢复
part 'viewport/viewport_controller.dart'; // 视口控制器

// 小组件
part 'widgets/mode_option.dart';        // 模式选项
part 'widgets/support_widgets.dart';    // 辅助组件
