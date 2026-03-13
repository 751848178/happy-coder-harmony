// LiveKit Plugin
//
// LiveKit 实时语音通信插件
//
// 注意：完整的 LiveKit 功能需要集成 LiveKit SDK
// 当前实现提供了基础的 WebSocket 连接和音频处理框架
//
// 功能：
// - 连接/断开 LiveKit 服务器
// - 发送/接收音频流
// - 麦克风静音控制
// - WebRTC 音频处理

import { Logger, LogTags } from '../utils/Logger';
import { webSocket } from '@kit.NetworkKit';
import http from '@ohos.net.http';
import common from '@ohos.app.ability.common';

/**
 * LiveKit 连接状态
 */
export enum LiveKitConnectionState {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  RECONNECTING = 'reconnecting',
  FAILED = 'failed'
}

/**
 * 音频配置
 */
export interface AudioConfig {
  sampleRate: number;       // 采样率 (16000, 24000, 48000)
  channelCount: number;     // 声道数 (1=单声道, 2=立体声)
  bitsPerSample: number;    // 每样本位数 (16)
  frameSize: number;        // 帧大小 (samples per frame)
  bufferSize: number;       // 缓冲区大小
}

/**
 * LiveKit 连接信息
 */
export interface LiveKitConnectionInfo {
  token: string;
  url: string;
  room: string;
  identity: string;
  serverUrl: string;
}

/**
 * LiveKit 音频事件回调
 */
export interface LiveKitAudioEventCallbacks {
  onAudioData?: (data: Uint8Array) => void;          // 收到音频数据
  onConnectionStateChanged?: (state: LiveKitConnectionState) => void;
  onError?: (error: string) => void;
  onMuteChanged?: (muted: boolean) => void;
  onParticipantJoined?: (participantId: string) => void;
  onParticipantLeft?: (participantId: string) => void;
  onSpeakingChanged?: (participantId: string, speaking: boolean) => void;
}

/**
 * WebSocket 事件类型
 */
enum WSMessageType {
  JOIN = 'join',
  OFFER = 'offer',
  ANSWER = 'answer',
  ICE_CANDIDATE = 'ice_candidate',
  TRACK_PUBLISHED = 'track_published',
  TRACK_SUBSCRIBED = 'track_subscribed',
  DATA = 'data',
  AUDIO_DATA = 'audio_data',
  MUTE = 'mute',
  UNMUTE = 'unmute',
  LEAVE = 'leave',
  ERROR = 'error'
}

/**
 * WebSocket 消息
 */
interface WSMessage {
  type: WSMessageType;
  data?: any;
  error?: string;
}

/**
 * LiveKit Plugin 类
 */
export class LiveKitPlugin {
  private connectionState: LiveKitConnectionState = LiveKitConnectionState.DISCONNECTED;
  private isMuted: boolean = false;
  private currentToken: string = '';
  private connectionInfo: LiveKitConnectionInfo | null = null;
  private eventCallbacks: LiveKitAudioEventCallbacks = {};

  // WebSocket 连接
  private ws: webSocket.WebSocket | null = null;
  private wsUrl: string = '';

  // 音频配置
  private audioConfig: AudioConfig = {
    sampleRate: 16000,
    channelCount: 1,
    bitsPerSample: 16,
    frameSize: 960,  // 20ms @ 16kHz
    bufferSize: 4096
  };

  // 音频处理（需要集成 @ohos.multimedia.media）
  private audioRecorder: any = null;
  private audioRenderer: any = null;
  private isRecording: boolean = false;

  // 上下文
  private abilityContext: common.Context | null = null;

  // 重连配置
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;
  private reconnectDelay: number = 1000;

  constructor() {
    Logger.debug(LogTags.LIVEKIT, 'LiveKit Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
    this.abilityContext = context;
  }

  // ========== 公共方法 ==========

  /**
   * 连接到 LiveKit 会话
   * @param token LiveKit 访问令牌
   * @returns 连接是否成功
   */
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
    return { ...this.audioConfig };
  }

  /**
   * 开始录制音频
   * @returns 是否成功
   */
  async startRecording(): Promise<boolean> {
    Logger.info(LogTags.LIVEKIT, 'Starting audio recording');

    if (this.isRecording) {
      Logger.warn(LogTags.LIVEKIT, 'Already recording');
      return true;
    }

    try {
      // 需要集成 @ohos.multimedia.media 进行音频录制
      // 以下是框架代码

      this.isRecording = true;
      Logger.info(LogTags.LIVEKIT, 'Audio recording started');
      return true;
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to start recording', error as Error);
      return false;
    }
  }

  /**
   * 停止录制音频
   */
  async stopRecording(): Promise<void> {
    Logger.info(LogTags.LIVEKIT, 'Stopping audio recording');

    if (!this.isRecording) {
      return;
    }

    try {
      this.isRecording = false;
      Logger.info(LogTags.LIVEKIT, 'Audio recording stopped');
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to stop recording', error as Error);
    }
  }

  /**
   * 开始播放音频
   * @returns 是否成功
   */
  async startPlayback(): Promise<boolean> {
    Logger.info(LogTags.LIVEKIT, 'Starting audio playback');

    try {
      // 需要集成 @ohos.multimedia.media 进行音频播放
      // 以下是框架代码

      Logger.info(LogTags.LIVEKIT, 'Audio playback started');
      return true;
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to start playback', error as Error);
      return false;
    }
  }

  /**
   * 停止播放音频
   */
  async stopPlayback(): Promise<void> {
    Logger.info(LogTags.LIVEKIT, 'Stopping audio playback');

    try {
      // 停止音频播放
      Logger.info(LogTags.LIVEKIT, 'Audio playback stopped');
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to stop playback', error as Error);
    }
  }

  /**
   * 测试通道是否可用
   * @returns 始终返回 true（通道健康检查）
   */
  async ping(): Promise<boolean> {
    return true;
  }

  // ========== 私有方法 ==========

  /**
   * 解析 token 获取连接信息
   * @param token JWT token
   * @returns 连接信息
   */
  private parseToken(token: string): LiveKitConnectionInfo {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid token format');
    }

    try {
      const payload = JSON.parse(atob(parts[1]));

      // LiveKit token 通常包含以下字段
      return {
        token: token,
        url: payload.vid || payload.iss || '',
        room: payload.room || payload.video?.room || 'default',
        identity: payload.sub || payload.identity || 'unknown',
        serverUrl: payload.iss || ''
      };
    } catch (e) {
      throw new Error('Failed to parse token');
    }
  }

  /**
   * 建立 WebSocket 连接
   */
  private async establishWebSocketConnection(info: LiveKitConnectionInfo): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        // 构建 WebSocket URL
        const wsProtocol = info.serverUrl.startsWith('https') ? 'wss' : 'ws';
        const wsHost = info.serverUrl.replace(/^https?:\/\//, '');
        this.wsUrl = `${wsProtocol}://${wsHost}`;

        Logger.debug(LogTags.LIVEKIT, `Connecting to WebSocket: ${this.wsUrl}`);

        // 创建 WebSocket
        this.ws = webSocket.createWebSocket();

        // 设置事件监听
        this.ws.on('open', () => {
          Logger.info(LogTags.LIVEKIT, 'WebSocket connected');
          resolve();
        });

        this.ws.on('message', (data: webSocket.WebSocketMessage) => {
          this.handleWSMessage(data);
        });

        this.ws.on('error', (error: ErrorEvent) => {
          Logger.error(LogTags.LIVEKIT, `WebSocket error: ${error.message}`);
          this.notifyError(`WebSocket error: ${error.message}`);
          reject(new Error(`WebSocket error: ${error.message}`));
        });

        this.ws.on('close', (code: number, reason: string) => {
          Logger.info(LogTags.LIVEKIT, `WebSocket closed: ${code} - ${reason}`);

          if (this.connectionState === LiveKitConnectionState.CONNECTED) {
            // 意外断开，尝试重连
            this.attemptReconnect();
          }
        });

        // 连接
        this.ws.connect(this.wsUrl, (err: BusinessError) => {
          if (err) {
            Logger.error(LogTags.LIVEKIT, `WebSocket connection failed: ${err.message}`);
            reject(new Error(`WebSocket connection failed: ${err.message}`));
          }
        });

      } catch (error) {
        Logger.error(LogTags.LIVEKIT, 'Failed to establish WebSocket connection', error as Error);
        reject(error);
      }
    });
  }

  /**
   * 关闭 WebSocket 连接
   */
  private closeWebSocket(): void {
    if (this.ws) {
      try {
        this.ws.close(1000, 'Normal closure');
        this.ws = null;
        Logger.debug(LogTags.LIVEKIT, 'WebSocket closed');
      } catch (error) {
        Logger.error(LogTags.LIVEKIT, 'Failed to close WebSocket', error as Error);
      }
    }
  }

  /**
   * 处理 WebSocket 消息
   */
  private handleWSMessage(message: webSocket.WebSocketMessage): void {
    try {
      let dataStr = '';
      if (typeof message.data === 'string') {
        dataStr = message.data;
      } else if (message.data instanceof ArrayBuffer) {
        dataStr = new TextDecoder().decode(message.data);
      }

      const msg: WSMessage = JSON.parse(dataStr);
      Logger.debug(LogTags.LIVEKIT, `Received message: ${msg.type}`);

      switch (msg.type) {
        case WSMessageType.AUDIO_DATA:
          this.handleAudioData(msg.data);
          break;
        case WSMessageType.TRACK_PUBLISHED:
          this.handleTrackPublished(msg.data);
          break;
        case WSMessageType.TRACK_SUBSCRIBED:
          this.handleTrackSubscribed(msg.data);
          break;
        case WSMessageType.MUTE:
        case WSMessageType.UNMUTE:
          this.handleRemoteMute(msg.type === WSMessageType.MUTE);
          break;
        case WSMessageType.ERROR:
          this.notifyError(msg.error || 'Unknown error');
          break;
        default:
          Logger.debug(LogTags.LIVEKIT, `Unhandled message type: ${msg.type}`);
      }
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to handle message', error as Error);
    }
  }

  /**
   * 发送 WebSocket 消息
   */
  private async sendMessage(message: WSMessage): Promise<void> {
    if (!this.ws || this.connectionState !== LiveKitConnectionState.CONNECTED) {
      Logger.warn(LogTags.LIVEKIT, 'Cannot send message: not connected');
      return;
    }

    try {
      const messageStr = JSON.stringify(message);
      this.ws.send(messageStr);
      Logger.debug(LogTags.LIVEKIT, `Sent message: ${message.type}`);
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to send message', error as Error);
    }
  }

  /**
   * 发送加入消息
   */
  private async sendJoinMessage(): Promise<void> {
    if (!this.connectionInfo) {
      return;
    }

    await this.sendMessage({
      type: WSMessageType.JOIN,
      data: {
        room: this.connectionInfo.room,
        identity: this.connectionInfo.identity,
        token: this.currentToken,
        audioConfig: this.audioConfig
      }
    });
  }

  /**
   * 尝试重连
   */
  private async attemptReconnect(): Promise<void> {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      Logger.error(LogTags.LIVEKIT, 'Max reconnect attempts reached');
      this.connectionState = LiveKitConnectionState.FAILED;
      this.notifyConnectionStateChanged(LiveKitConnectionState.FAILED);
      return;
    }

    this.reconnectAttempts++;
    this.connectionState = LiveKitConnectionState.RECONNECTING;
    this.notifyConnectionStateChanged(LiveKitConnectionState.RECONNECTING);

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    Logger.info(LogTags.LIVEKIT, `Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    setTimeout(async () => {
      try {
        await this.disconnect();
        const success = await this.connectSession(this.currentToken);
        if (!success) {
          this.attemptReconnect();
        }
      } catch (error) {
        Logger.error(LogTags.LIVEKIT, 'Reconnect failed', error as Error);
        this.attemptReconnect();
      }
    }, delay);
  }

  /**
   * 初始化音频处理
   */
  private async initializeAudio(): Promise<void> {
    Logger.debug(LogTags.LIVEKIT, 'Initializing audio processing');

    // 需要集成 @ohos.multimedia.media
    // 以下是框架代码

    Logger.debug(LogTags.LIVEKIT, `Audio config: ${JSON.stringify(this.audioConfig)}`);
  }

  /**
   * 停止音频处理
   */
  private stopAudio(): void {
    Logger.debug(LogTags.LIVEKIT, 'Stopping audio processing');

    this.stopRecording();
    this.stopPlayback();
  }

  /**
   * 处理收到的音频数据
   */
  private handleAudioData(data: any): void {
    try {
      if (data.audio) {
        const audioData = this.base64ToUint8Array(data.audio);
        Logger.debug(LogTags.LIVEKIT, `Received ${audioData.length} bytes of audio`);

        // 播放音频数据
        this.playAudioData(audioData);

        // 触发回调
        if (this.eventCallbacks.onAudioData) {
          this.eventCallbacks.onAudioData(audioData);
        }
      }
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to handle audio data', error as Error);
    }
  }

  /**
   * 播放音频数据
   */
  private async playAudioData(data: Uint8Array): Promise<void> {
    // 需要集成 @ohos.multimedia.media 播放音频
    // 以下是框架代码
  }

  /**
   * 处理轨道发布
   */
  private handleTrackPublished(data: any): void {
    Logger.info(LogTags.LIVEKIT, `Track published: ${JSON.stringify(data)}`);

    if (data.participantId && this.eventCallbacks.onParticipantJoined) {
      this.eventCallbacks.onParticipantJoined(data.participantId);
    }
  }

  /**
   * 处理轨道订阅
   */
  private handleTrackSubscribed(data: any): void {
    Logger.info(LogTags.LIVEKIT, `Track subscribed: ${JSON.stringify(data)}`);
  }

  /**
   * 处理远程静音
   */
  private handleRemoteMute(muted: boolean): void {
    Logger.info(LogTags.LIVEKIT, `Remote muted: ${muted}`);

    if (this.eventCallbacks.onMuteChanged) {
      this.eventCallbacks.onMuteChanged(muted);
    }
  }

  /**
   * 通知连接状态变化
   */
  private notifyConnectionStateChanged(state: LiveKitConnectionState): void {
    if (this.eventCallbacks.onConnectionStateChanged) {
      this.eventCallbacks.onConnectionStateChanged(state);
    }
  }

  /**
   * 通知错误
   */
  private notifyError(error: string): void {
    if (this.eventCallbacks.onError) {
      this.eventCallbacks.onError(error);
    }
  }

  /**
   * 通知静音状态变化
   */
  private notifyMuteChanged(muted: boolean): void {
    if (this.eventCallbacks.onMuteChanged) {
      this.eventCallbacks.onMuteChanged(muted);
    }
  }

  /**
   * Uint8Array 转 Base64
   */
  private uint8ArrayToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < uint8Array.length; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * Base64 转 Uint8Array
   */
  private base64ToUint8Array(base64: string): Uint8Array {
    const binary = atob(base64);
    const length = binary.length;
    const buffer = new ArrayBuffer(length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < length; i++) {
      uint8Array[i] = binary.charCodeAt(i);
    }
    return uint8Array;
  }

  /**
   * 清理资源
   */
  dispose(): void {
    Logger.debug(LogTags.LIVEKIT, 'Disposing LiveKit Plugin');

    this.disconnect();
    this.eventCallbacks = {};
  }
}

/**
 * LiveKit 管理器（单例）
 */
class LiveKitManager {
  private static instance: LiveKitPlugin;

  static getInstance(): LiveKitPlugin {
    if (!LiveKitManager.instance) {
      LiveKitManager.instance = new LiveKitPlugin();
    }
    return LiveKitManager.instance;
  }
}

/**
 * 导出单例实例
 */
export const liveKitPlugin = LiveKitManager.getInstance();
