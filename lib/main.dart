import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/config/server_config_service.dart';
import 'app/routes/app_router.dart';
import 'app/widgets/happy_link_gate.dart';
import 'app/widgets/session_background_refresh_gate.dart';
import 'features/storage/domain/storage_service.dart';
import 'shared/utils/extensions.dart';

/// ============================================================================
/// 应用入口文件
/// ============================================================================
/// 
/// 这是整个 Flutter 应用的启动入口，负责：
/// 1. 初始化 Flutter 框架绑定
/// 2. 配置全局错误处理机制
/// 3. 初始化核心服务（存储、服务器配置等）
/// 4. 启动应用根组件
/// 
/// 【学习要点】
/// - main() 函数是 Dart 程序的入口点
/// - async 关键字表示这是一个异步函数，可以使用 await
/// - WidgetsFlutterBinding 是 Flutter 框架与原生平台的桥梁
/// - ProviderScope 是 Riverpod 状态管理的根容器
/// ============================================================================

/// 应用主入口函数
/// 
/// 【执行流程】
/// 1. 确保 Flutter 框架已初始化
/// 2. 配置错误捕获和日志记录
/// 3. 初始化存储服务（本地数据库）
/// 4. 初始化服务器配置服务
/// 5. 启动应用
void main() async {
  // 【步骤1】确保 Flutter 框架已初始化
  // 这是在 runApp() 之前执行异步操作的必要步骤
  // 它会初始化 Flutter 引擎和原生平台的通信通道
  WidgetsFlutterBinding.ensureInitialized();
  Logger.info('main() start');

  // 【步骤2】配置全局错误处理
  // Flutter 框架内的同步错误会被这个回调捕获
  // 例如：Widget 构建过程中的异常、布局错误等
  FlutterError.onError = (FlutterErrorDetails details) {
    Logger.error('[FlutterCrash] ${details.exceptionAsString()}');
    final context = details.context?.toDescription();
    if (context != null && context.isNotEmpty) {
      Logger.error('[FlutterCrash][context] $context');
    }
    if (details.stack != null) {
      final lines = details.stack.toString().split('\n').take(5).join(' | ');
      Logger.error('[FlutterCrash][stack] $lines');
    }
    // 在开发模式下，仍然显示红屏错误提示
    FlutterError.presentError(details);
  };
  
  // 捕获异步错误（Future、async/await 中未被 try-catch 捕获的错误）
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    Logger.error('[FlutterCrash][async] $error');
    final lines = stack.toString().split('\n').take(5).join(' | ');
    Logger.error('[FlutterCrash][async-stack] $lines');
    return false; // 返回 false 表示错误未被完全处理，会继续抛出
  };

  // 自定义错误显示 Widget
  // 当 Widget 构建失败时，会显示这个自定义的错误界面，而不是默认的红屏
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final exceptionText = details.exceptionAsString();
    Logger.error('[FlutterCrash][widget] $exceptionText');
    if (details.stack != null) {
      Logger.error('[FlutterCrash][widget-stack]\n${details.stack}');
    }
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App failed to render',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A runtime error interrupted startup.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    kReleaseMode ? 'Please restart the app.' : exceptionText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 【步骤3】初始化核心服务
  // 这些服务必须在应用启动前完成初始化
  
  // 初始化本地存储服务（Hive 数据库）
  // 用于缓存会话数据、消息历史等
  Logger.info('Initializing StorageService');
  await StorageService.instance.initialize();
  
  // 初始化服务器配置服务
  // 加载 API 端点、服务器地址等配置信息
  Logger.info('Initializing ServerConfigService');
  await ServerConfigService.instance.init();
  Logger.info('runApp() start');

  // TODO: 初始化其他服务（根据需要取消注释）
  // await Firebase.initializeApp();
  // await NotificationService.initialize();

  // 【步骤4】启动应用
  // ProviderScope 是 Riverpod 状态管理的根容器
  // 所有的 Provider 都必须在 ProviderScope 内部才能使用
  runApp(
    const ProviderScope(
      child: HappyCoderApp(),
    ),
  );
}

/// ============================================================================
/// 应用根组件
/// ============================================================================
/// 
/// 这是应用的根 Widget，负责：
/// 1. 配置应用主题（亮色/暗色）
/// 2. 配置路由系统（使用 go_router）
/// 3. 包裹全局功能组件（HappyLink、后台刷新等）
/// 
/// 【学习要点】
/// - ConsumerWidget 是 Riverpod 提供的 Widget，可以访问 Provider
/// - MaterialApp.router 是使用声明式路由的 Material Design 应用
/// - builder 参数可以在路由 Widget 外层包裹额外的 Widget
/// ============================================================================
class HappyCoderApp extends ConsumerWidget {
  const HappyCoderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Logger.info('HappyCoderApp.build()');
    
    // 【关键】监听路由 Provider
    // ref.watch 会在 Provider 值变化时自动重建 Widget
    // routerProvider 提供了整个应用的路由配置
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // 应用标题（显示在任务切换器中）
      title: AppConfig.appName,
      
      // 隐藏右上角的 Debug 标签
      debugShowCheckedModeBanner: false,
      
      // 主题配置
      theme: AppTheme.lightTheme,        // 亮色主题
      darkTheme: AppTheme.darkTheme,     // 暗色主题
      themeMode: ThemeMode.system,       // 跟随系统主题
      
      // 路由配置（使用 go_router）
      routerConfig: router,
      
      // builder 用于在路由 Widget 外层包裹额外的功能组件
      builder: (context, child) {
        // 如果路由 Widget 为空，显示加载指示器
        final routedChild = child ??
            const Material(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
        
        // 【功能层级包裹】从内到外：
        // 1. routedChild - 路由显示的页面
        // 2. HappyLinkGate - 处理深度链接（从外部打开应用）
        // 3. SessionBackgroundRefreshGate - 管理会话后台刷新
        // 4. MediaQuery - 固定文本缩放比例为 1.0（防止系统字体大小影响布局）
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: SessionBackgroundRefreshGate(
            child: HappyLinkGate(child: routedChild),
          ),
        );
      },
    );
  }
}
