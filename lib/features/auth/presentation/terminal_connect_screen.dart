import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import 'scan_qr_screen.dart';

/// 电脑连接页面
///
/// 使用 happy://terminal?{publicKeyBase64Url} 链接授权终端
class TerminalConnectScreen extends ConsumerStatefulWidget {
  const TerminalConnectScreen({super.key, this.authUrl});

  final String? authUrl;

  @override
  ConsumerState<TerminalConnectScreen> createState() =>
      _TerminalConnectScreenState();
}

class _TerminalConnectScreenState extends ConsumerState<TerminalConnectScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _showEntrySheet = false;
  String? _errorMessage;
  String? _connectFailureMessage;
  String? _publicKeyPreview;
  String? _parsedLink;

  @override
  void initState() {
    super.initState();
    _linkController.addListener(_handleLinkChanged);
    if (widget.authUrl != null && widget.authUrl!.trim().isNotEmpty) {
      _linkController.text = widget.authUrl!.trim();
      _previewLink(showError: false);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _linkController.text.trim().isNotEmpty) {
        return;
      }
      setState(() {
        _showEntrySheet = true;
      });
    });
  }

  @override
  void dispose() {
    _linkController
      ..removeListener(_handleLinkChanged)
      ..dispose();
    super.dispose();
  }

  void _handleLinkChanged() {
    final current = _linkController.text.trim();
    if (_parsedLink != null && current != _parsedLink) {
      setState(() {
        _parsedLink = null;
        _publicKeyPreview = null;
      });
    }
  }

  Future<void> _connectTerminal() async {
    if (_isConnecting) return;
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      setState(() {
        _errorMessage = '请输入电脑端授权链接';
      });
      return;
    }

    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      setState(() {
        _errorMessage = '请先登录或恢复账户';
      });
      return;
    }

    if (!_previewLink()) {
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _connectFailureMessage = null;
      _showEntrySheet = false;
    });

    try {
      final notifier = ref.read(authStateProvider.notifier);
      await notifier.connectTerminal(link);

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
      await _showSuccessDialogAndExit();
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectFailureMessage = '连接失败: $e';
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
    final data = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(
          title: '扫描电脑端二维码',
          description: '将摄像头对准电脑上显示的授权二维码，识别后会自动返回。',
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isScanning = false;
      if (data != null && data.trim().isNotEmpty) {
        _linkController.text = data.trim();
      }
    });
    if (data == null || data.trim().isEmpty) {
      return;
    }
    _previewLink(showError: false);
    setState(() {
      _showEntrySheet = false;
    });
  }

  Future<void> _showSuccessDialogAndExit() async {
    await _prepareConnectedState();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('连接成功'),
          content: const Text('电脑连接授权成功'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    context.go('${AppRoutes.home}?tab=sessions');
  }

  Future<void> _prepareConnectedState() async {
    final authState = ref.read(authStateProvider);
    final futures = <Future<void>>[
      ref.read(sessionStateProvider.notifier).loadSessions(),
    ];
    if (authState.isAuthenticated) {
      final credentials = authState.credentials!;
      final socketState = ref.read(socketStateProvider);
      if (!socketState.isConnected) {
        futures.add(
          ref.read(socketStateProvider.notifier).initialize(
                machineId: credentials.machineId,
                token: credentials.token,
              ),
        );
      }
    }

    await Future.wait(futures);
  }

  bool _previewLink({bool showError = true}) {
    final rawValue = _extractPublicKeyValue(_linkController.text);
    if (rawValue == null || rawValue.isEmpty) {
      if (showError) {
        setState(() {
          _errorMessage = '电脑端授权链接格式不正确';
          _parsedLink = null;
          _publicKeyPreview = null;
        });
      }
      return false;
    }

    try {
      _decodeBase64Flexible(rawValue);
    } catch (_) {
      if (showError) {
        setState(() {
          _errorMessage = '电脑端授权链接格式不正确';
          _parsedLink = null;
          _publicKeyPreview = null;
        });
      }
      return false;
    }

    final preview = rawValue.length > 24
        ? '${rawValue.substring(0, 12)}...${rawValue.substring(rawValue.length - 12)}'
        : rawValue;
    setState(() {
      _errorMessage = null;
      _parsedLink = _linkController.text.trim();
      _publicKeyPreview = preview;
    });
    return true;
  }

  String? _extractPublicKeyValue(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    if (!cleaned.startsWith('happy://terminal?')) {
      return cleaned;
    }

    final uri = Uri.tryParse(cleaned);
    if (uri == null) {
      return cleaned.substring('happy://terminal?'.length);
    }

    final publicKey = uri.queryParameters['publicKey'] ??
        uri.queryParameters['key'] ??
        uri.queryParameters['token'];
    if (publicKey != null && publicKey.isNotEmpty) {
      return publicKey;
    }

    if (uri.queryParameters.length == 1) {
      final entry = uri.queryParameters.entries.first;
      if (entry.value.isEmpty && entry.key.isNotEmpty) {
        return entry.key;
      }
    }

    if (uri.query.isNotEmpty) {
      return uri.query;
    }

    return cleaned.substring('happy://terminal?'.length);
  }

  List<int> _decodeBase64Flexible(String input) {
    var standard = input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (standard.length % 4 != 0) {
      standard += '=';
    }
    return base64Decode(standard);
  }

  void _clearInput() {
    _linkController.clear();
    setState(() {
      _errorMessage = null;
      _connectFailureMessage = null;
      _parsedLink = null;
      _publicKeyPreview = null;
    });
  }

  void _dismissScreen() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('${AppRoutes.home}?tab=sessions');
  }

  void _openEntrySheet() {
    setState(() {
      _showEntrySheet = true;
      _errorMessage = null;
      _connectFailureMessage = null;
    });
  }

  void _closeEntrySheet() {
    if (_parsedLink == null) {
      _dismissScreen();
      return;
    }
    setState(() {
      _showEntrySheet = false;
      _errorMessage = null;
    });
  }

  void _submitEntrySheet() {
    if (_previewLink()) {
      setState(() {
        _showEntrySheet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _dismissScreen,
        ),
        title: const Text('连接电脑'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.computer,
                            color: AppTheme.brandColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '连接电脑终端',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neutral900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '输入电脑端授权链接或扫描二维码，确认后才会授权当前账户。',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.neutral600,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '当前 Happy Server：${AppConfig.serverUrl}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_parsedLink == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '等待输入终端链接',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '默认会先弹出输入框。你也可以直接扫描二维码。',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.neutral600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openEntrySheet,
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: const Text('输入链接'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isScanning ? null : _startScan,
                                icon: Icon(
                                  _isScanning
                                      ? Icons.qr_code_2
                                      : Icons.qr_code_scanner,
                                  size: 18,
                                ),
                                label: Text(_isScanning ? '扫码中...' : '扫码连接'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.brandColor,
                                  side: const BorderSide(
                                      color: AppTheme.brandColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _publicKeyPreview ?? _parsedLink ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.neutral700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '端到端加密授权',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.neutral700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: _openEntrySheet,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('重新输入'),
                              ),
                              TextButton.icon(
                                onPressed: _isScanning ? null : _startScan,
                                icon:
                                    const Icon(Icons.qr_code_scanner, size: 18),
                                label: const Text('扫码替换'),
                              ),
                              if (_linkController.text.isNotEmpty)
                                TextButton(
                                  onPressed: _clearInput,
                                  child: const Text('清空'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_errorMessage != null)
                      _buildMessage(
                        message: _errorMessage!,
                        color: AppTheme.errorColor,
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isConnecting ? null : _connectTerminal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '连接电脑',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_showEntrySheet) _buildEntrySheetOverlay(),
            if (_isConnecting || _connectFailureMessage != null)
              _buildStatusOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrySheetOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.38),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.shadowLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '输入终端链接',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _closeEntrySheet,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '粘贴 `happy://terminal?...` 链接，或者直接扫描电脑二维码。',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage != null
                            ? AppTheme.errorColor
                            : AppTheme.neutral300,
                      ),
                    ),
                    child: TextField(
                      controller: _linkController,
                      autofocus: true,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitEntrySheet(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'happy://terminal?BASE64URL_PUBLIC_KEY',
                        hintStyle: TextStyle(color: AppTheme.neutral400),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildMessage(
                      message: _errorMessage!,
                      color: AppTheme.errorColor,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isScanning ? null : _startScan,
                          icon: Icon(
                            _isScanning
                                ? Icons.qr_code_2
                                : Icons.qr_code_scanner,
                            size: 18,
                          ),
                          label: Text(_isScanning ? '扫码中...' : '扫码'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitEntrySheet,
                          child: const Text('继续'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    final isFailure = _connectFailureMessage != null && !_isConnecting;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.32),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width - 48,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFailure ? Icons.error_outline : Icons.sync_rounded,
                  size: 30,
                  color: isFailure ? AppTheme.errorColor : AppTheme.brandColor,
                ),
                const SizedBox(height: 12),
                Text(
                  isFailure ? '连接失败' : '正在连接终端',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFailure ? _connectFailureMessage! : '正在校验授权链接并向电脑端发送批准响应。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral600,
                    height: 1.45,
                  ),
                ),
                if (!isFailure) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(strokeWidth: 2.4),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismissScreen,
                        child: const Text('返回'),
                      ),
                    ),
                    if (isFailure) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _connectFailureMessage = null;
                            });
                            _connectTerminal();
                          },
                          child: const Text('重试'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({required String message, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
