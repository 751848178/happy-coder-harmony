import { Logger, LogTags } from '../utils/Logger';
import { LiveKitAudioEventCallbacks, LiveKitConnectionState } from './LiveKitPluginModels';
import { LiveKitPluginSupport } from './LiveKitPluginSupport';

export class LiveKitPluginConnection extends LiveKitPluginSupport {
  async connectSession(token: string): Promise<boolean> {
    Logger.info(LogTags.LIVEKIT, `Connecting to LiveKit with token: ${token.substring(0, 20)}...`);

    this.connectionState = LiveKitConnectionState.CONNECTING;
    this.currentToken = token;

    try {
      // 解析 token 获取连接信息
      this.connectionInfo = this.parseToken(token);

      // 建立 WebSocket 连接
      await this.establishWebSocketConnection(this.connectionInfo);

      // 初始化音频处理
      await this.initializeAudio();

      // 发送加入消息
      await this.sendJoinMessage();

      this.connectionState = LiveKitConnectionState.CONNECTED;
      this.reconnectAttempts = 0;
      this.notifyConnectionStateChanged(LiveKitConnectionState.CONNECTED);

      Logger.info(LogTags.LIVEKIT, 'Successfully connected to LiveKit');
      return true;

    } catch (error) {
      this.connectionState = LiveKitConnectionState.FAILED;
      this.notifyError(`Connection failed: ${(error as Error).message}`);
      Logger.error(LogTags.LIVEKIT, 'Connection failed', error as Error);
      return false;
    }
  }

  /**
   * 断开 LiveKit 会话
   */
  async disconnect(): Promise<void> {
    Logger.info(LogTags.LIVEKIT, 'Disconnecting from LiveKit');

    this.connectionState = LiveKitConnectionState.DISCONNECTED;

    // 发送离开消息
    await this.sendMessage({
      type: WSMessageType.LEAVE
    });

    // 停止音频处理
    this.stopAudio();

    // 关闭 WebSocket 连接
    this.closeWebSocket();

    // 重置状态
    this.currentToken = '';
    this.connectionInfo = null;
    this.reconnectAttempts = 0;

    Logger.info(LogTags.LIVEKIT, 'Disconnected from LiveKit');
  }

  /**
   * 发送音频数据
   * @param data 音频数据 (ArrayBuffer)
   */
  async sendAudio(data: ArrayBuffer): Promise<void> {
    if (this.connectionState !== LiveKitConnectionState.CONNECTED) {
      Logger.warn(LogTags.LIVEKIT, 'Cannot send audio: not connected');
      throw new Error('Not connected to LiveKit');
    }

    if (this.isMuted) {
      Logger.debug(LogTags.LIVEKIT, 'Audio muted, skipping send');
      return;
    }

    try {
      // 将音频数据转换为 Uint8Array
      const uint8Array = new Uint8Array(data);

      // 发送音频数据
      await this.sendMessage({
        type: WSMessageType.AUDIO_DATA,
        data: {
          audio: this.uint8ArrayToBase64(uint8Array),
          sampleRate: this.audioConfig.sampleRate,
          channels: this.audioConfig.channelCount
        }
      });

      Logger.debug(LogTags.LIVEKIT, `Sent ${data.byteLength} bytes of audio`);
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to send audio', error as Error);
      throw error;
    }
  }

  /**
   * 切换静音状态
   * @returns 新的静音状态
   */
  async toggleMute(): Promise<boolean> {
    this.isMuted = !this.isMuted;

    Logger.info(LogTags.LIVEKIT, `Mute state changed: ${this.isMuted}`);

    // 通知服务器
    await this.sendMessage({
      type: this.isMuted ? WSMessageType.MUTE : WSMessageType.UNMUTE
    });

    this.notifyMuteChanged(this.isMuted);

    return this.isMuted;
  }

  /**
   * 获取静音状态
   * @returns 当前是否静音
   */
  getMuted(): boolean {
    return this.isMuted;
  }

  /**
   * 获取连接状态
   * @returns 当前连接状态
   */
  getConnectionState(): LiveKitConnectionState {
    return this.connectionState;
  }

  /**
   * 设置事件回调
   * @param callbacks 事件回调对象
   */
  setEventCallbacks(callbacks: LiveKitAudioEventCallbacks): void {
    this.eventCallbacks = { ...this.eventCallbacks, ...callbacks };
    Logger.debug(LogTags.LIVEKIT, 'Event callbacks updated');
  }

  /**
   * 设置音频配置
   * @param config 音频配置
   */
  setAudioConfig(config: Partial<AudioConfig>): void {
    this.audioConfig = { ...this.audioConfig, ...config };
    Logger.debug(LogTags.LIVEKIT, `Audio config updated: ${JSON.stringify(this.audioConfig)}`);
  }

  /**
   * 获取音频配置
   * @returns 当前音频配置
   */
  getAudioConfig(): AudioConfig {
}
