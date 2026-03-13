import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../../features/auth/data/auth_repository.dart';

/// 手动输入 Secret Key 恢复页面
///
/// 用于通过输入 Secret Key 来恢复账户访问权限
class ManualRestoreScreen extends ConsumerStatefulWidget {
  const ManualRestoreScreen({super.key, this.authUrl});

  final String? authUrl;

  @override
  ConsumerState<ManualRestoreScreen> createState() => _ManualRestoreScreenState();
}

class _ManualRestoreScreenState extends ConsumerState<ManualRestoreScreen> {
  final TextEditingController _secretKeyController = TextEditingController();
  bool _isRestoring = false;
  String? _errorMessage;
  bool _showSecret = false;

  @override
  void initState() {
    super.initState();
    final authUrl = widget.authUrl?.trim();
    if (authUrl != null && authUrl.isNotEmpty) {
      _secretKeyController.text = authUrl;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final authState = ref.read(authStateProvider);
        if (!authState.isAuthenticated) {
          _restoreAccount();
        }
      });
    }
  }

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  /// 恢复账户
  Future<void> _restoreAccount() async {
    final secretKey = _secretKeyController.text.trim();

    if (secretKey.isEmpty) {
      setState(() {
        _errorMessage = '请输入 Secret Key';
      });
      return;
    }

    // 终端连接链接（happy://terminal?...）应走终端连接流程
    if (_looksLikeTerminalLink(secretKey)) {
      if (mounted) {
        context.push(
          '${AppRoutes.terminalConnect}?url=${Uri.encodeComponent(secretKey)}',
        );
      }
      return;
    }

    final isRestoreLink = _looksLikeRestoreLink(secretKey);

    // 格式化 Secret Key
    final formattedKey = _formatSecretKey(secretKey);

    // 检查是否为账号授权链接（非 Secret Key）
    if (_looksLikeAccountAuthLink(formattedKey)) {
      setState(() {
        _errorMessage = '这是授权链接，不是 Secret Key，请使用终端生成的 Secret Key';
      });
      return;
    }

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);

      if (isRestoreLink) {
        await authNotifier.loginWithLink(secretKey);
      } else {
        String base64Secret;
        try {
          base64Secret = _processSecretKey(formattedKey);
          Logger.info('Secret key processed: ${base64Secret.substring(0, 16)}...');
        } catch (e) {
          throw Exception('Secret Key 格式无效: ${e.toString()}');
        }

        final authRepository = AuthRepository.instance;
        await authRepository.loginWithSecret(base64Secret);
        await authNotifier.loginWithHappySecret(base64Secret);
      }

      final authState = ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        throw Exception(authState.errorMessage ?? '恢复失败');
      }

      if (mounted) {
        context.go(AppRoutes.home);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('账户恢复成功'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '恢复失败: $e';
          _isRestoring = false;
        });
      }
    }
  }

  bool _looksLikeTerminalLink(String input) {
    final cleaned = input.trim();
    return cleaned.startsWith('happy://terminal?');
  }

  bool _looksLikeRestoreLink(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) return false;
    if (_looksLikeTerminalLink(cleaned) || _looksLikeAccountAuthLink(cleaned)) {
      return false;
    }
    return cleaned.startsWith('happy://') ||
        cleaned.startsWith('handy://') ||
        cleaned.startsWith('https://happy.link/');
  }

  /// 处理 Secret Key，自动检测格式并转换为 Base64
  String _processSecretKey(String key) {
    // 移除连字符和空格
    final cleaned = key.replaceAll(RegExp(r'[-\s]'), '');

    Logger.info('=== _processSecretKey START ===');
    Logger.info('Input key: "$key"');
    Logger.info('Cleaned key: "$cleaned"');
    Logger.info('Cleaned key length: ${cleaned.length}');

    // 检测格式
    final hasBase64Chars = cleaned.contains('_') || cleaned.contains('-');
    Logger.info('hasBase64Chars: $hasBase64Chars');
    Logger.info('_looksLikeBase64: ${_looksLikeBase64(cleaned)}');

    // Happy Coder 通常使用 Base64URL 格式的 secret key
    // Base64URL 字符集: A-Z, a-z, 0-9, -, _ (no padding)
    if (hasBase64Chars || _looksLikeBase64(cleaned)) {
      // 看起来像 Base64/Base64URL，直接使用或转换
      Logger.info('Detected Base64/Base64URL format');

      // 如果是 Base64URL，转换为标准 Base64
      if (cleaned.contains('_') || cleaned.contains('-')) {
        Logger.info('Converting Base64URL to Base64');
        final standardBase64 = cleaned
            .replaceAll('_', '/')
            .replaceAll('-', '+');

        Logger.info('Standard Base64 (before padding): "$standardBase64"');

        // 添加 padding 使长度为 4 的倍数
        var padded = standardBase64;
        while (padded.length % 4 != 0) {
          padded += '=';
        }

        Logger.info('Standard Base64 (with padding): "$padded"');
        Logger.info('=== _processSecretKey END (Base64URL) ===');
        return padded;
      } else {
        // 已经是标准 Base64，直接返回（添加 padding）
        Logger.info('Standard Base64 format, adding padding');
        var padded = cleaned;
        while (padded.length % 4 != 0) {
          padded += '=';
        }

        Logger.info('Standard Base64 (with padding): "$padded"');
        Logger.info('=== _processSecretKey END (Base64) ===');
        return padded;
      }
    } else {
      // 可能是 Base32 或其他格式，尝试解码
      Logger.info('Attempting Base32 decode');
      final decoded = _base32Decode(cleaned);

      if (decoded.length < 16 || decoded.length > 32) {
        throw Exception('Invalid decoded key length: ${decoded.length} bytes');
      }

      // 编码为 Base64
      final base64 = base64Encode(decoded);
      Logger.info('Decoded Base32 and encoded to Base64: $base64');
      return base64;
    }
  }

  /// 判断是否为账号授权链接格式（happy:///account?base64url=...）
  bool _looksLikeAccountAuthLink(String key) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) return false;
    return cleaned.startsWith('base64url=') || cleaned.contains('base64url=');
  }

  /// 检查字符串是否像 Base64
  bool _looksLikeBase64(String s) {
    // Base64 字符集: A-Z, a-z, 0-9, +, /
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=_\-]+$');
    return base64Pattern.hasMatch(s) && s.length >= 16;
  }

  /// 格式化 Secret Key
  String _formatSecretKey(String key) {
    // 移除空格和制表符
    var cleaned = key.replaceAll(RegExp(r'\s+'), '');

    Logger.info('Formatting secret key: "$cleaned"');

    // 如果是 happy:// 链接格式，提取 secret key 参数
    if (cleaned.startsWith('happy://')) {
      Logger.info('Detected happy:// link');
      final uri = Uri.tryParse(cleaned);
      if (uri != null) {
        Logger.info('Parsed URI - scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}, query: ${uri.query}, queryParameters: ${uri.queryParameters}');

        // 首先尝试从查询部分获取 (优先级更高)
        if (uri.query.isNotEmpty) {
          // 格式可能是：
          // 1. happy:///?secret=XXXXX (标准查询参数)
          // 2. happy://terminal?ISledSBcsyQ4io4QOWip3sw003OuFw0VTW12PUb2bGs (直接值)

          // 首先检查是否有标准查询参数 (key=value 格式)
          String? secret;
          if (uri.queryParameters.isNotEmpty) {
            secret = uri.queryParameters['secret'] ?? uri.queryParameters['key'] ?? uri.queryParameters['token'];
          }

          // 如果找到了标准查询参数，使用它；否则使用整个查询字符串作为 secret
          if (secret != null) {
            Logger.info('Extracted secret from query param: $secret');
            cleaned = secret;
          } else {
            // 没有标准查询参数，使用整个查询字符串作为 secret
            // 例如: happy://terminal?ISledSBcsyQ4io4QOWip3sw003OuFw0VTW12PUb2bGs
            // 注意: Dart URI 解析器会将 "key" 当作键名，值设为空字符串
            // 所以 queryParameters 不是空，但没有我们要找的键
            Logger.info('Extracted secret from direct query: ${uri.query}');
            cleaned = uri.query;
          }
        } else {
          // 尝试从路径中获取 (happy:///XXXXXXXXXXXXXXXXXXXXXX)
          var path = uri.path;
          // 移除前导斜杠
          if (path.startsWith('/')) {
            path = path.substring(1);
          }
          if (path.isNotEmpty) {
            Logger.info('Extracted secret from path: $path');
            cleaned = path;
          }
        }
      }
    }

    Logger.info('Formatted secret key: "$cleaned"');
    return cleaned;
  }

  /// Base32-Crockford 解码
  List<int> _base32Decode(String input) {
    // Happy Coder 使用 Base32-Crockford 编码
    // 移除连字符和空格
    final cleaned = input.replaceAll(RegExp(r'[-\s]'), '');

    Logger.info('Base32 decoding: ${cleaned.length} characters: "$cleaned"');

    // Base32-Crockford 字符集映射
    // 使用标准 RFC 4648 Base32: A-Z, 2-7
    // 同时支持 Crockford 变体的部分字符（标准化后）
    const base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    // 创建字符到值的映射
    final charMap = <String, int>{};
    for (int i = 0; i < base32Alphabet.length; i++) {
      charMap[base32Alphabet[i]] = i;
    }

    // 标准化: 小写转大写，处理容易混淆的字符
    final normalized = cleaned.toUpperCase();
    final mapped = StringBuffer();

    for (int i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      // Base32-Crockford 字符标准化
      String mappedChar;
      switch (char) {
        case '0':
          mappedChar = 'O';  // 0 -> O
          break;
        case '1':
          mappedChar = 'I';  // 1 -> I
          break;
        case '8':
          mappedChar = 'B';  // 8 -> B
          break;
        case '9':
          mappedChar = 'P';  // 9 -> P
          break;
        default:
          mappedChar = char;
      }

      // 检查是否为有效字符
      if (!charMap.containsKey(mappedChar)) {
        // 尝试直接映射
        if (charMap.containsKey(char)) {
          mapped.write(char);
        } else {
          final mappedValue = charMap[mappedChar];
          Logger.error('Invalid Base32 character: $char (mapped: $mappedValue)');
          throw FormatException('Invalid Base32 character: $char');
        }
      } else {
        mapped.write(mappedChar);
      }
    }

    final finalStr = mapped.toString();
    Logger.info('Normalized Base32 string: "$finalStr"');

    // 解码 Base32 (每个字符代表 5 位)
    List<int> result = [];
    int buffer = 0;
    int bits = 0;

    for (int i = 0; i < finalStr.length; i++) {
      final char = finalStr[i];
      final value = charMap[char];

      if (value == null) {
        Logger.error('Invalid Base32 character: $char');
        throw FormatException('Invalid Base32 character: $char');
      }

      buffer = (buffer << 5) | value;
      bits += 5;

      if (bits >= 8) {
        bits -= 8;
        result.add((buffer >> bits) & 0xFF);
      }
    }

    Logger.info('Base32 decoded to ${result.length} bytes');

    return result;
  }

  /// 切换 Secret Key 显示
  void _toggleSecretVisibility() {
    setState(() {
      _showSecret = !_showSecret;
    });
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
          onPressed: () => context.pop(),
        ),
        title: const Text('恢复账户'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 说明
              Container(
                padding: const EdgeInsets.all(20),
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.vpn_key,
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
                                '输入您的 Secret Key',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neutral900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Secret Key 用于恢复您对账户的访问权限。请确保从可信来源获取。',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Secret Key 输入
              Text(
                'Secret Key',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                ),
              ),
              const SizedBox(height: 8),
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
                  controller: _secretKeyController,
                  obscureText: !_showSecret,
                  maxLines: _showSecret ? 4 : 1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'XXXXX-XXXXX-XXXXX...',
                    hintStyle: TextStyle(color: AppTheme.neutral400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _toggleSecretVisibility,
                    child: Text(
                      _showSecret ? '隐藏' : '显示',
                      style: TextStyle(
                        color: AppTheme.brandColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_secretKeyController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _secretKeyController.clear();
                      },
                      child: const Text('清空'),
                    ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 恢复按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRestoring ? null : _restoreAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRestoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '恢复账户',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
