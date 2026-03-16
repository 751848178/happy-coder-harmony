// Push Plugin
//
// 鸿蒙推送通知插件
//
// 功能：
// - 初始化推送服务 (Push Kit)
// - 请求推送权限
// - 接收推送消息
// - 处理点击事件
// - 获取 Token

import { Logger, LogTags } from '../utils/Logger';
import pushService from '@ohos.push';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

/**
 * 推送权限状态
 */
export enum PushPermissionStatus {
  GRANTED = 'granted',
  DENIED = 'denied',
  NOT_DETERMINED = 'not_determined',
  DISABLED = 'disabled'
}

/**
 * 推送消息类型
 */
export enum PushMessageType {
  NEW_MESSAGE = 'new_message',
  SESSION_UPDATE = 'session_update',
  SYSTEM = 'system',
  VOICE_CALL = 'voice_call',
  NOTIFICATION = 'notification'
}

/**
 * 推送消息
 */
export interface PushMessage {
  id: string;
  title: string;
  body: string;
  type: PushMessageType;
  data: Record<string, string>;
  timestamp: number;
  extras?: Record<string, any>;
}

/**
 * 推送事件类型
 */
export enum PushEventType {
  TOKEN_REFRESH = 'token_refresh',
  MESSAGE_RECEIVED = 'message_received',
  MESSAGE_CLICKED = 'message_clicked',
  ERROR = 'error',
  CONNECTED = 'connected',
  DISCONNECTED = 'disconnected'
}

/**
 * 推送事件
 */
export interface PushEvent {
  type: PushEventType;
  data?: any;
  error?: string;
}

/**
 * 推送通知配置
 */
export interface PushNotificationConfig {
  channelId: string;          // 通知渠道 ID
  channelName: string;         // 通知渠道名称
  enableVibrate: boolean;      // 是否震动
  enableLight: boolean;        // 是否亮灯
  enableSound: boolean;        // 是否播放声音
  importance: number;          // 重要性 (1-5)
}

/**
 * 推送连接状态
 */
export enum PushConnectionStatus {
  DISCONNECTED = 0,
  CONNECTING = 1,
  CONNECTED = 2,
  FAILED = 3
}

/**
 * 推送事件回调
 */
export interface PushEventCallbacks {
  onTokenRefresh?: (token: string) => void;
  onMessageReceived?: (message: PushMessage) => void;
  onMessageClicked?: (message: PushMessage) => void;
  onError?: (error: string) => void;
  onConnected?: () => void;
  onDisconnected?: () => void;
}

/**
 * Push Plugin 类
 */
