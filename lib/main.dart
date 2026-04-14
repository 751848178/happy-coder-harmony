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

/// 应用入口
///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.info('main() start');

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
    FlutterError.presentError(details);
  };
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    Logger.error('[FlutterCrash][async] $error');
    final lines = stack.toString().split('\n').take(5).join(' | ');
    Logger.error('[FlutterCrash][async-stack] $lines');
    return false;
  };

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

  // 初始化存储服务
  Logger.info('Initializing StorageService');
  await StorageService.instance.initialize();
  Logger.info('Initializing ServerConfigService');
  await ServerConfigService.instance.init();
  Logger.info('runApp() start');

  // TODO: 初始化其他服务
  // await Firebase.initializeApp();
  // await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: HappyCoderApp(),
    ),
  );
}

/// 应用根组件
class HappyCoderApp extends ConsumerWidget {
  const HappyCoderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Logger.info('HappyCoderApp.build()');
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        final routedChild = child ??
            const Material(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
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
