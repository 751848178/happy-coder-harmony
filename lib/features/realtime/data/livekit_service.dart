import 'dart:async';
import 'dart:typed_data';

import '../../../shared/utils/extensions.dart';
import '../../../harmony/harmony_bridge.dart';

part 'livekit_service_state.dart';

/// LiveKit 实时语音服务
///
/// 处理实时语音通话和音频传输
class LiveKitService {
  LiveKitService._();

  static final LiveKitService instance = LiveKitService._();

  /// 当前连接状态
  bool _isConnected = false;

  /// 是否静音
  bool _isMuted = false;

  /// 连接状态流
  final _connectionStateController =
      StreamController<LiveKitConnectionState>.broadcast();

  /// 音频流
  final _audioStreamController = StreamController<List<int>>.broadcast();

  /// 连接状态
  Stream<LiveKitConnectionState> get connectionStream =>
      _connectionStateController.stream;

  /// 音频流
  Stream<List<int>> get audioStream => _audioStreamController.stream;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 是否静音
  bool get isMuted => _isMuted;

  /// 连接到会话
  Future<bool> connect(String token, String roomId) async {
    if (_isConnected) {
      return true;
    }
    _connectionStateController.add(LiveKitConnectionStates.connecting);
    Logger.info('Connecting to LiveKit room: $roomId');

    try {
      // 通过 Harmony Bridge 连接到 LiveKit
      final success = await HarmonyBridge.connectLiveKit(token);
      if (success) {
        _isConnected = true;
        _connectionStateController.add(LiveKitConnectionStates.connected);
        Logger.info('Connected to LiveKit room: $roomId');
        return true;
      } else {
        _connectionStateController.add(LiveKitConnectionStates.error('连接失败'));
        return false;
      }
    } catch (e) {
      Logger.error('Failed to connect to LiveKit: $e');
      _connectionStateController.add(
        LiveKitConnectionStates.error(e.toString()),
      );
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    _isConnected = false;
    try {
      // 通过 Harmony Bridge 断开连接
      await HarmonyBridge.disconnectLiveKit();
      _connectionStateController.add(LiveKitConnectionStates.disconnected);
      Logger.info('Disconnected from LiveKit');
    } catch (e) {
      Logger.error('Failed to disconnect from LiveKit: $e');
    }
  }

  /// 发送音频数据
  Future<void> sendAudio(List<int> audioData) async {
    if (!_isConnected) {
      Logger.warning('Cannot send audio: not connected');
      return;
    }

    if (_isMuted) {
      Logger.info('Audio muted, skipping send');
      return;
    }

    try {
      // 通过 Harmony Bridge 发送音频
      await HarmonyBridge.sendLiveKitAudio(Uint8List.fromList(audioData));
      Logger.debug('Sent ${audioData.length} audio samples');
    } catch (e) {
      Logger.error('Failed to send audio: $e');
    }
  }

  /// 切换静音状态
  Future<void> toggleMute() async {
    try {
      // 通过 Harmony Bridge 切换静音
      await HarmonyBridge.toggleLiveKitMute();
      _isMuted = !_isMuted;
      Logger.info('Audio muted: $_isMuted');
    } catch (e) {
      Logger.error('Failed to toggle mute: $e');
    }
  }

  /// 获取静音状态
  Future<bool> getMuted() async {
    try {
      // 通过 Harmony Bridge 获取静音状态
      final muted = await HarmonyBridge.getLiveKitMuted();
      _isMuted = muted;
      return muted;
    } catch (e) {
      Logger.error('Failed to get muted state: $e');
      return false;
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    try {
      // 通过 Harmony Bridge 开始录音
      await HarmonyBridge.connectLiveKit('recording_token');
      Logger.info('Starting audio recording');
    } catch (e) {
      Logger.error('Failed to start recording: $e');
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    try {
      // 通过 Harmony Bridge 停止录音
      await HarmonyBridge.disconnectLiveKit();
      Logger.info('Stopped audio recording');
    } catch (e) {
      Logger.error('Failed to stop recording: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _connectionStateController.close();
    _audioStreamController.close();
  }
}
