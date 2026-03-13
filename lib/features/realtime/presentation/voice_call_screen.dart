import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../realtime/data/livekit_service.dart';

/// 语音通话屏幕
///
/// 显示实时语音通话界面
class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.roomId,
    required this.participantName,
    this.isOutgoing = false,
  });

  final String roomId;
  final String participantName;
  final bool isOutgoing;

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with TickerProviderStateMixin {
  // 音频可视化
  final List<double> _audioLevels = List.filled(50, 0.0);
  Timer? _audioLevelTimer;

  // 通话状态
  bool _isMuted = false;
  bool _isConnected = false;
  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _audioLevelTimer?.cancel();
    LiveKitService.instance.dispose();
    super.dispose();
  }

  /// 初始化通话
  Future<void> _initializeCall() async {
    try {
      await LiveKitService.instance.connect('token', widget.roomId);
      setState(() => _isConnected = true);
      _callStartTime = DateTime.now();
      _startAudioLevelTimer();
      Logger.info('Voice call initialized');
    } catch (e) {
      Logger.error('Failed to initialize voice call: $e');
    }
  }

  /// 启动音频级别定时器
  void _startAudioLevelTimer() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        // 模拟音频级别变化
        _updateAudioLevels();
      });
    });
  }

  /// 更新音频级别
  void _updateAudioLevels() {
    // 模拟随机音频数据
    for (int i = 0; i < _audioLevels.length; i++) {
      final base = 0.1 + (i % 10) * 0.05;
      final variation = (math.Random().nextDouble() - 0.5) * 0.15;
      _audioLevels[i] = (base + variation).clamp(0.0, 1.0);
    }
  }

  /// 切换静音
  Future<void> _toggleMute() async {
    await LiveKitService.instance.toggleMute();
    setState(() => _isMuted = !_isMuted);
  }

  /// 结束通话
  Future<void> _endCall() async {
    await LiveKitService.instance.disconnect();
    setState(() => _isConnected = false);

    // TODO: 导航回聊天界面
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 音频可视化背景
                  _buildAudioVisualization(context),

                  // 顶部信息
                  _buildTopInfo(context),

                  // 底部控制
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildControls(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建音频可视化
  Widget _buildAudioVisualization(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AudioWavePainter(_audioLevels),
      ),
    );
  }

  /// 构建顶部信息
  Widget _buildTopInfo(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 参与者头像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandColor.withValues(alpha: 0.2),
                  border: Border.fromBorderSide(
                    const BorderSide(color: Colors.white, width: 3),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.participantName.isNotEmpty
                        ? widget.participantName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 参与者名称
              Text(
                widget.participantName.isNotEmpty
                    ? widget.participantName
                    : 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // 通话状态
              Text(
                _isConnected
                    ? _getCallDuration()
                    : (widget.isOutgoing ? 'Calling...' : 'Connecting...'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取通话时长
  String _getCallDuration() {
    if (_callStartTime == null) return '00:00';
    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 构建底部控制
  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 静音按钮
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            onTap: _toggleMute,
          ),
          // 挂断按钮
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
          border: Border.fromBorderSide(
            BorderSide(color: color, width: 2),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 32,
        ),
      ),
    );
  }
}

/// 音频波形绘制器
class _AudioWavePainter extends CustomPainter {
  final List<double> levels;

  _AudioWavePainter(this.levels);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.shortestSide / 2 - 20;

    for (int i = 0; i < levels.length; i++) {
      final angle = (i / levels.length) * 2 * math.pi;
      final radius = maxRadius * levels[i];
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AudioWavePainter oldDelegate) {
    return oldDelegate.levels != levels;
  }
}
