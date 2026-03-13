import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/models/auth_models.dart';
import '../../../shared/models/auth_state.dart';
import '../data/auth_repository.dart';
import '../data/token_storage_service.dart';

/// 登录流程测试页面
///
/// 用于测试和调试整个登录流程
class LoginTestScreen extends ConsumerStatefulWidget {
  const LoginTestScreen({super.key});

  @override
  ConsumerState<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends ConsumerState<LoginTestScreen> {
  final TextEditingController _linkController = TextEditingController(
    text: '', // 在此输入测试链接
  );
  final List<TestLog> _logs = [];
  bool _isRunning = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录流程测试'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 输入区域
            _buildInputArea(),
            // 按钮区域
            _buildButtonArea(),
            // 日志区域
            Expanded(child: _buildLogArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '测试链接',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'happy://...',
              hintStyle: TextStyle(
                color: AppTheme.neutral400,
              ),
              filled: true,
              fillColor: AppTheme.neutral50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.neutral300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.brandColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持格式：happy://xxx 或 https://happy.link/xxxxx',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
            onPressed: _isRunning ? null : _runFullTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('完整流程测试'),
          ),
          ElevatedButton(
            onPressed: _isRunning ? null : _testParseLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neutral600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('测试链接解析'),
          ),
          ElevatedButton(
            onPressed: _isRunning ? null : _testStorage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neutral600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('测试存储'),
          ),
          ElevatedButton(
            onPressed: _isRunning ? null : _clearCredentials,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('清除凭证'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '测试日志',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_logs.length} 条',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      '暂无日志',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogItem(log, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(TestLog log, int index) {
    Color textColor = Colors.white;
    IconData? icon;
    switch (log.level) {
      case LogType.info:
        textColor = Colors.lightBlue;
        icon = Icons.info_outline;
        break;
      case LogType.success:
        textColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case LogType.warning:
        textColor = Colors.orange;
        icon = Icons.warning_amber_outlined;
        break;
      case LogType.error:
        textColor = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 16, color: textColor),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.step,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatTime(log.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
                if (log.details != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.details!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';
  }

  // ========== 测试方法 ==========

  /// 运行完整流程测试
  Future<void> _runFullTest() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _clearLogs();

    try {
      // 步骤1: 验证输入
      _addLog(LogType.info, '步骤1', '验证输入链接', _linkController.text);
      await Future.delayed(const Duration(milliseconds: 100));

      final linkUrl = _linkController.text.trim();
      if (linkUrl.isEmpty) {
        _addLog(LogType.error, '步骤1', '链接为空', null);
        return;
      }

      if (!linkUrl.startsWith('happy://')) {
        _addLog(LogType.warning, '步骤1', '链接格式不正确', '应以 happy:// 开头');
        return;
      }

      _addLog(LogType.success, '步骤1', '输入验证通过', '链接长度: ${linkUrl.length}');

      // 步骤2: 解析链接
      _addLog(LogType.info, '步骤2', '解析链接', null);
      await Future.delayed(const Duration(milliseconds: 100));

      final secretKey = linkUrl.substring(8);
      _addLog(LogType.success, '步骤2', '链接解析成功', 'Secret key 长度: ${secretKey.length}');
      _addLog(LogType.info, '步骤2', 'Secret key (前100字符)', secretKey.length > 100 ? secretKey.substring(0, 100) : secretKey);

      // 步骤3: 检查存储服务
      _addLog(LogType.info, '步骤3', '检查存储服务', null);
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        final storage = TokenStorageService.instance;
        _addLog(LogType.success, '步骤3', '存储服务已初始化', null);
      } catch (e) {
        _addLog(LogType.error, '步骤3', '存储服务初始化失败', e.toString());
        return;
      }

      // 步骤4: 检查是否已登录
      _addLog(LogType.info, '步骤4', '检查登录状态', null);
      await Future.delayed(const Duration(milliseconds: 100));

      final authRepo = AuthRepository.instance;
      final isAuthenticated = await authRepo.isAuthenticated();
      _addLog(LogType.success, '步骤4', '登录状态检查完成', '已登录: $isAuthenticated');

      // 步骤5: 调用登录 API
      _addLog(LogType.info, '步骤5', '调用登录 API', 'AuthRepository.loginWithSecretKey');
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        final stopwatch = Stopwatch()..start();
        final response = await authRepo.loginWithSecretKey(secretKey);
        stopwatch.stop();

        _addLog(LogType.success, '步骤5', '登录 API 调用成功', '耗时: ${stopwatch.elapsedMilliseconds}ms');
        _addLog(LogType.info, '步骤5', '响应 Token (前50字符)', response.token.length > 50 ? response.token.substring(0, 50) : response.token);
        _addLog(LogType.info, '步骤5', 'Machine ID', response.machineId);
        _addLog(LogType.info, '步骤5', 'Encryption Type', response.encryptionType.name);
        _addLog(LogType.info, '步骤5', 'Public Key', response.publicKey?.substring(0, 50) ?? 'null');
        _addLog(LogType.info, '步骤5', 'Machine Key', response.machineKey?.substring(0, 50) ?? 'null');

        // 步骤6: 保存凭证
        _addLog(LogType.info, '步骤6', '保存凭证到存储', null);
        await Future.delayed(const Duration(milliseconds: 100));

        final storage = TokenStorageService.instance;
        await storage.saveToken(response.token);
        await storage.saveMachineId(response.machineId);
        await storage.saveEncryptionType(response.encryptionType);
        if (response.encryptionKey != null) {
          await storage.saveEncryptionKey(response.encryptionKey!);
        }
        if (response.publicKey != null) {
          await storage.savePublicKey(response.publicKey!);
        }
        if (response.machineKey != null) {
          await storage.saveMachineKey(response.machineKey!);
        }

        _addLog(LogType.success, '步骤6', '凭证保存成功', null);

        // 步骤7: 验证保存的凭证
        _addLog(LogType.info, '步骤7', '验证保存的凭证', null);
        await Future.delayed(const Duration(milliseconds: 100));

        final credentials = await authRepo.getCredentials();
        if (credentials != null) {
          _addLog(LogType.success, '步骤7', '凭证验证成功', 'Token 长度: ${credentials.token.length}');
        } else {
          _addLog(LogType.error, '步骤7', '凭证验证失败', '无法读取保存的凭证');
        }

        // 步骤8: 更新认证状态
        _addLog(LogType.info, '步骤8', '更新认证状态', null);
        await Future.delayed(const Duration(milliseconds: 100));

        ref.read(authStateProvider.notifier).state = AuthState.authenticated(credentials: Credentials(
          token: response.token,
          machineId: response.machineId,
          encryptionKey: response.encryptionKey ?? '',
          encryptionType: response.encryptionType,
          publicKey: response.publicKey ?? '',
          machineKey: response.machineKey ?? '',
        ));

        _addLog(LogType.success, '步骤8', '认证状态已更新', null);
        _addLog(LogType.success, '完成', '登录流程测试全部通过！', '可以点击返回按钮进入主页');

      } on Exception catch (e) {
        _addLog(LogType.error, '步骤5', '登录 API 调用失败', e.toString());
        Logger.error('Login test failed: $e');
      }
    } catch (e) {
      _addLog(LogType.error, '异常', '测试过程中发生未捕获的异常', e.toString());
      Logger.error('Test exception: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  /// 测试链接解析
  void _testParseLink() {
    _clearLogs();
    final linkUrl = _linkController.text.trim();

    _addLog(LogType.info, '测试', '链接解析测试', linkUrl);

    if (linkUrl.isEmpty) {
      _addLog(LogType.error, '测试', '链接为空', null);
      return;
    }

    if (linkUrl.startsWith('happy://')) {
      final value = linkUrl.substring(8);
      _addLog(LogType.success, '测试', 'happy:// 格式识别成功', '值长度: ${value.length}');
      _addLog(LogType.info, '测试', '提取的值', value.length > 200 ? value.substring(0, 200) : value);
    } else if (linkUrl.startsWith('handy://')) {
      _addLog(LogType.warning, '测试', 'handy:// 格式识别（旧格式）', '已废弃');
    } else {
      _addLog(LogType.error, '测试', '无法识别链接格式', '支持的格式：happy://xxx 或 https://happy.link/xxxxx');
    }
  }

  /// 测试存储
  Future<void> _testStorage() async {
    _clearLogs();
    _addLog(LogType.info, '测试', '存储测试', null);

    try {
      final storage = TokenStorageService.instance;

      // 测试写入
      _addLog(LogType.info, '测试', '测试写入', null);
      await storage.write(key: 'test_key', value: 'test_value_${DateTime.now().millisecondsSinceEpoch}');
      _addLog(LogType.success, '测试', '写入成功', null);

      // 测试读取
      _addLog(LogType.info, '测试', '测试读取', null);
      final value = await storage.read('test_key');
      _addLog(LogType.success, '测试', '读取成功', value ?? 'null');

      // 测试删除
      _addLog(LogType.info, '测试', '测试删除', null);
      await storage.delete('test_key');
      _addLog(LogType.success, '测试', '删除成功', null);

      // 验证删除
      final deletedValue = await storage.read('test_key');
      if (deletedValue == null) {
        _addLog(LogType.success, '测试', '删除验证成功', 'key 不存在');
      } else {
        _addLog(LogType.warning, '测试', '删除验证失败', 'key 仍然存在');
      }

    } catch (e) {
      _addLog(LogType.error, '测试', '存储测试失败', e.toString());
    }
  }

  /// 清除凭证
  Future<void> _clearCredentials() async {
    _clearLogs();
    _addLog(LogType.info, '操作', '清除凭证', null);

    try {
      final storage = TokenStorageService.instance;
      await storage.clearAll();
      _addLog(LogType.success, '操作', '凭证已清除', null);

      final token = await storage.getToken();
      _addLog(LogType.info, '验证', 'Token 是否存在', token != null ? '是' : '否');

    } catch (e) {
      _addLog(LogType.error, '操作', '清除凭证失败', e.toString());
    }
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  void _addLog(LogType level, String step, String message, String? details) {
    setState(() {
      _logs.add(TestLog(
        level: level,
        step: step,
        message: message,
        details: details,
        timestamp: DateTime.now(),
      ));
    });
  }
}

enum LogType { info, success, warning, error }

class TestLog {
  const TestLog({
    required this.level,
    required this.step,
    required this.message,
    this.details,
    required this.timestamp,
  });

  final LogType level;
  final String step;
  final String message;
  final String? details;
  final DateTime timestamp;
}
