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
