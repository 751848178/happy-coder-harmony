import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../realtime/data/livekit_service.dart';

part 'content.dart';
part 'painter.dart';

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
    LiveKitService.instance.dispose();
    super.dispose();
  }

  /// 初始化通话
  Future<void> _initializeCall() async {
    try {
      await LiveKitService.instance.connect('token', widget.roomId);
      setState(() => _isConnected = true);
      _callStartTime = DateTime.now();
      Logger.info('Voice call initialized');
    } catch (e) {
      Logger.error('Failed to initialize voice call: $e');
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
                  // 音频可视化背景 — 独立组件，高频刷新仅影响自身
                  const _AudioVisualization(),

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
}

/// 独立的音频可视化组件。
///
/// 内部维护自己的 `_audioLevels` 和 50ms 定时器，
/// `setState` 仅重建此 `CustomPaint`，不影响外层页面。
class _AudioVisualization extends StatefulWidget {
  const _AudioVisualization();

  @override
  State<_AudioVisualization> createState() => _AudioVisualizationState();
}

class _AudioVisualizationState extends State<_AudioVisualization> {
  final List<double> _audioLevels = List.filled(50, 0.0);
  Timer? _audioLevelTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _audioLevelTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(_updateAudioLevels);
    });
  }

  void _updateAudioLevels() {
    for (int i = 0; i < _audioLevels.length; i++) {
      final base = 0.1 + (i % 10) * 0.05;
      final variation = (math.Random().nextDouble() - 0.5) * 0.15;
      _audioLevels[i] = (base + variation).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AudioWavePainter(_audioLevels),
      ),
    );
  }
}
