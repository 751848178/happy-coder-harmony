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
export class PushPlugin {
  private isInitialized: boolean = false;
  private currentToken: string = '';
  private permissionStatus: PushPermissionStatus = PushPermissionStatus.NOT_DETERMINED;
  private initialMessage: PushMessage | null = null;
  private eventCallbacks: PushEventCallbacks = {};

  // Push Kit 相关
  private abilityContext: common.Context | null = null;
  private pushService: pushService.PushService | null = null;
  private connectionStatus: PushConnectionStatus = PushConnectionStatus.DISCONNECTED;

  // 通知配置
  private notificationConfig: PushNotificationConfig = {
    channelId: 'happy_coder_channel',
    channelName: 'Happy Coder',
    enableVibrate: true,
    enableLight: true,
    enableSound: true,
    importance: 4
  };

  // 事件流
  private eventStream: PushEvent[] = [];

  constructor() {
    Logger.debug(LogTags.PUSH, 'Push Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
    this.abilityContext = context;
  }

  // ========== 公共方法 ==========

  /**
   * 初始化推送服务
   * @param appId 应用 ID
   * @returns 是否初始化成功
   */
  async initialize(appId: string): Promise<boolean> {
    Logger.info(LogTags.PUSH, `Initializing push service with appId: ${appId}`);

    if (this.isInitialized) {
      Logger.warn(LogTags.PUSH, 'Push service already initialized');
      return true;
    }

    if (!this.abilityContext) {
      Logger.error(LogTags.PUSH, 'Ability context not set');
      return false;
    }

    try {
      // 创建 PushService 实例
      this.pushService = pushService.createPushService(this.abilityContext);

      // 注册回调
      this.registerPushCallbacks();

      // 获取推送 Token
      await this.getPushToken();

      // 创建通知渠道
      await this.createNotificationChannel();

      this.isInitialized = true;
      this.connectionStatus = PushConnectionStatus.CONNECTED;

      Logger.info(LogTags.PUSH, 'Push service initialized successfully');
      this.notifyConnected();

      return true;
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Push service initialization failed', error as Error);
      this.connectionStatus = PushConnectionStatus.FAILED;
      this.notifyError(`Initialization failed: ${(error as Error).message}`);
      return false;
    }
  }

  /**
   * 请求推送权限
   * @returns 是否获得权限
   */
  async requestPermissions(): Promise<boolean> {
    Logger.info(LogTags.PUSH, 'Requesting push permissions');

    if (!this.abilityContext) {
      Logger.error(LogTags.PUSH, 'Ability context not set');
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);

      // 检查权限状态
      const status = await atManager.checkAccessToken(
        this.abilityContext.applicationInfo.accessTokenId,
        'ohos.permission.NOTIFICATION_CONTROLLER'
      );

      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.permissionStatus = PushPermissionStatus.GRANTED;
        Logger.info(LogTags.PUSH, 'Permission already granted');
        return true;
      }

      // 请求权限
      const result = await atManager.requestPermissionsFromUser(
        this.abilityContext,
        ['ohos.permission.NOTIFICATION_CONTROLLER']
      );

      const granted = result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      this.permissionStatus = granted ? PushPermissionStatus.GRANTED : PushPermissionStatus.DENIED;

      Logger.info(LogTags.PUSH, `Permission ${granted ? 'granted' : 'denied'}`);
      return granted;
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Permission request failed', error as Error);
      this.permissionStatus = PushPermissionStatus.DENIED;
      return false;
    }
  }

  /**
   * 获取推送 Token
   * @returns 当前推送 Token
   */
  async getToken(): Promise<string> {
    if (!this.isInitialized || !this.pushService) {
      Logger.warn(LogTags.PUSH, 'Push service not initialized');
      return '';
    }

    return this.currentToken;
  }

  /**
   * 重新获取 Token
   * @returns 新的 Token
   */
  async refreshToken(): Promise<string | null> {
    Logger.info(LogTags.PUSH, 'Refreshing push token');

    if (!this.pushService) {
      Logger.error(LogTags.PUSH, 'Push service not initialized');
      return null;
    }

    try {
      const token = await this.pushService.getPushToken();
      this.currentToken = token;

      Logger.info(LogTags.PUSH, `Token refreshed: ${token.substring(0, 20)}...`);

      // 触发回调
      this.notifyTokenRefresh(token);

      return token;
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Token refresh failed', error as Error);
      this.notifyError(`Token refresh failed: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * 获取初始通知消息
   * @returns 应用启动时的初始通知消息
   */
  async getInitialMessage(): Promise<string | null> {
    Logger.debug(LogTags.PUSH, 'Getting initial message');

    if (this.initialMessage) {
      const message = JSON.stringify(this.initialMessage);
      Logger.debug(LogTags.PUSH, `Initial message: ${message.substring(0, 50)}...`);
      return message;
    }

    return null;
  }

  /**
   * 订阅推送事件流
   * @returns 事件流
   */
  getEventStream(): PushEvent[] {
    return [...this.eventStream];
  }

  /**
   * 设置事件回调
   * @param callbacks 事件回调对象
   */
  setEventCallbacks(callbacks: PushEventCallbacks): void {
    this.eventCallbacks = { ...this.eventCallbacks, ...callbacks };
    Logger.debug(LogTags.PUSH, 'Event callbacks updated');
  }

  /**
   * 获取权限状态
   * @returns 当前权限状态
   */
  getPermissionStatus(): PushPermissionStatus {
    return this.permissionStatus;
  }

  /**
   * 检查初始化状态
   * @returns 是否已初始化
   */
  isReady(): boolean {
    return this.isInitialized;
  }

  /**
   * 获取连接状态
   * @returns 连接状态
   */
  getConnectionStatus(): PushConnectionStatus {
    return this.connectionStatus;
  }

  /**
   * 显示本地通知
   * @param title 标题
   * @param content 内容
   * @param extras 附加数据
   */
  async showLocalNotification(title: string, content: string, extras?: Record<string, any>): Promise<boolean> {
    Logger.info(LogTags.PUSH, `Showing local notification: ${title}`);

    if (!this.pushService) {
      Logger.error(LogTags.PUSH, 'Push service not initialized');
      return false;
    }

    try {
      const notificationRequest: pushService.NotificationRequest = {
        id: Date.now(),
        content: {
          notificationContentType: pushService.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content
          }
        }
      };

      if (extras) {
        notificationRequest.data = extras;
      }

      await this.pushService.publish(notificationRequest);
      Logger.info(LogTags.PUSH, 'Local notification published');
      return true;
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Failed to show local notification', error as Error);
      return false;
    }
  }

  /**
   * 清除所有通知
   * @returns 是否成功
   */
  async clearAllNotifications(): Promise<boolean> {
    Logger.info(LogTags.PUSH, 'Clearing all notifications');

    if (!this.pushService) {
      Logger.error(LogTags.PUSH, 'Push service not initialized');
      return false;
    }

    try {
      await this.pushService.cancelAllNotifications();
      Logger.info(LogTags.PUSH, 'All notifications cleared');
      return true;
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Failed to clear notifications', error as Error);
      return false;
    }
  }

  /**
   * 设置通知渠道
   * @param config 通知配置
   */
  async setNotificationChannel(config: Partial<PushNotificationConfig>): Promise<boolean> {
    this.notificationConfig = { ...this.notificationConfig, ...config };

    if (this.isInitialized) {
      return await this.createNotificationChannel();
    }

    return true;
  }

  /**
   * 测试通道是否可用
   * @returns 始终返回 true
   */
  async ping(): Promise<boolean> {
    return true;
  }

  // ========== 私有方法 ==========

  /**
   * 注册推送回调
   */
  private registerPushCallbacks(): void {
    if (!this.pushService) {
      return;
    }

    // Token 刷新回调
    this.pushService.on('receivePushToken', (token: string) => {
      Logger.info(LogTags.PUSH, `Token refreshed: ${token.substring(0, 20)}...`);
      this.currentToken = token;

      // 添加到事件流
      this.eventStream.push({
        type: PushEventType.TOKEN_REFRESH,
        data: { token }
      });

      // 触发回调
      this.notifyTokenRefresh(token);
    });

    // 接收消息回调
    this.pushService.on('receiveMessage', (message: pushService.PushMessage) => {
      Logger.info(LogTags.PUSH, `Received push message: ${message.data}`);

      const pushMessage: PushMessage = this.parsePushMessage(message);

      // 添加到事件流
      this.eventStream.push({
        type: PushEventType.MESSAGE_RECEIVED,
        data: pushMessage
      });

      // 触发回调
      this.notifyMessageReceived(pushMessage);
    });

    // 消息点击回调
    this.pushService.on('clickMessage', (message: pushService.PushMessage) => {
      Logger.info(LogTags.PUSH, `Message clicked: ${message.data}`);

      const pushMessage: PushMessage = this.parsePushMessage(message);
      this.initialMessage = pushMessage;

      // 添加到事件流
      this.eventStream.push({
        type: PushEventType.MESSAGE_CLICKED,
        data: pushMessage
      });

      // 触发回调
      this.notifyMessageClicked(pushMessage);
    });

    // 连接状态回调
    this.pushService.on('connectState', (state: number) => {
      Logger.info(LogTags.PUSH, `Connection state changed: ${state}`);

      this.connectionStatus = state as PushConnectionStatus;

      if (state === PushConnectionStatus.CONNECTED) {
        this.eventStream.push({
          type: PushEventType.CONNECTED
        });
        this.notifyConnected();
      } else if (state === PushConnectionStatus.DISCONNECTED) {
        this.eventStream.push({
          type: PushEventType.DISCONNECTED
        });
        this.notifyDisconnected();
      }
    });

    Logger.debug(LogTags.PUSH, 'Push callbacks registered');
  }

  /**
   * 取消推送回调
   */
  private unregisterPushCallbacks(): void {
    if (!this.pushService) {
      return;
    }

    this.pushService.off('receivePushToken');
    this.pushService.off('receiveMessage');
    this.pushService.off('clickMessage');
    this.pushService.off('connectState');

    Logger.debug(LogTags.PUSH, 'Push callbacks unregistered');
  }

  /**
   * 获取推送 Token
   */
  private async getPushToken(): Promise<void> {
    if (!this.pushService) {
      return;
    }

    try {
      const token = await this.pushService.getPushToken();
      this.currentToken = token;

      Logger.info(LogTags.PUSH, `Push token: ${token.substring(0, 20)}...`);

      // 添加到事件流
      this.eventStream.push({
        type: PushEventType.TOKEN_REFRESH,
        data: { token }
      });
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Failed to get push token', error as Error);
      throw error;
    }
  }

  /**
   * 创建通知渠道
   */
  private async createNotificationChannel(): Promise<boolean> {
    if (!this.pushService) {
      return false;
    }

    try {
      const channel: pushService.NotificationChannel = {
        id: this.notificationConfig.channelId,
        name: this.notificationConfig.channelName,
        importance: this.notificationConfig.importance,
        enabled: true,
        vibrationEnabled: this.notificationConfig.enableVibrate,
        lightEnabled: this.notificationConfig.enableLight,
        soundEnabled: this.notificationConfig.enableSound
      };

      await this.pushService.createNotificationChannel(channel);
      Logger.debug(LogTags.PUSH, `Notification channel created: ${channel.id}`);
      return true;
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Failed to create notification channel', error as Error);
      return false;
    }
  }

  /**
   * 解析推送消息
   */
  private parsePushMessage(message: pushService.PushMessage): PushMessage {
    const now = Date.now();

    try {
      const data = message.data || {};

      // 尝试解析额外数据
      let extras: Record<string, any> | undefined;
      if (message.extraData) {
        try {
          extras = JSON.parse(message.extraData);
        } catch (e) {
          extras = { raw: message.extraData };
        }
      }

      return {
        id: message.id || String(now),
        title: message.title || 'Happy Coder',
        body: message.body || '',
        type: this.determineMessageType(data),
        data: data,
        timestamp: now,
        extras: extras
      };
    } catch (error) {
      Logger.error(LogTags.PUSH, 'Failed to parse push message', error as Error);

      return {
        id: String(now),
        title: 'Happy Coder',
        body: 'New notification',
        type: PushMessageType.NOTIFICATION,
        data: {},
        timestamp: now
      };
    }
  }

  /**
   * 确定消息类型
   */
  private determineMessageType(data: Record<string, string>): PushMessageType {
    const type = data.type || data.messageType || '';

    switch (type) {
      case 'new_message':
        return PushMessageType.NEW_MESSAGE;
      case 'session_update':
        return PushMessageType.SESSION_UPDATE;
      case 'system':
        return PushMessageType.SYSTEM;
      case 'voice_call':
        return PushMessageType.VOICE_CALL;
      default:
        return PushMessageType.NOTIFICATION;
    }
  }

  /**
   * 通知 Token 刷新
   */
  private notifyTokenRefresh(token: string): void {
    if (this.eventCallbacks.onTokenRefresh) {
      this.eventCallbacks.onTokenRefresh(token);
    }
  }

  /**
   * 通知收到消息
   */
  private notifyMessageReceived(message: PushMessage): void {
    if (this.eventCallbacks.onMessageReceived) {
      this.eventCallbacks.onMessageReceived(message);
    }
  }

  /**
   * 通知消息被点击
   */
  private notifyMessageClicked(message: PushMessage): void {
    if (this.eventCallbacks.onMessageClicked) {
      this.eventCallbacks.onMessageClicked(message);
    }
  }

  /**
   * 通知错误
   */
  private notifyError(error: string): void {
    Logger.error(LogTags.PUSH, error);

    // 添加到事件流
    this.eventStream.push({
      type: PushEventType.ERROR,
      error
    });

    // 触发回调
    if (this.eventCallbacks.onError) {
      this.eventCallbacks.onError(error);
    }
  }

  /**
   * 通知已连接
   */
  private notifyConnected(): void {
    if (this.eventCallbacks.onConnected) {
      this.eventCallbacks.onConnected();
    }
  }

  /**
   * 通知已断开
   */
  private notifyDisconnected(): void {
    if (this.eventCallbacks.onDisconnected) {
      this.eventCallbacks.onDisconnected();
    }
  }

  /**
   * 清理资源
   */
  dispose(): void {
    Logger.debug(LogTags.PUSH, 'Disposing Push Plugin');

    this.unregisterPushCallbacks();

    if (this.pushService) {
      this.pushService = null;
    }

    this.isInitialized = false;
    this.eventStream = [];
    this.initialMessage = null;
  }
}

/**
 * Push 管理器（单例）
 */
class PushManager {
  private static instance: PushPlugin;

  static getInstance(): PushPlugin {
    if (!PushManager.instance) {
      PushManager.instance = new PushPlugin();
    }
    return PushManager.instance;
  }
}

/**
 * 导出单例实例
 */
export const pushPlugin = PushManager.getInstance();
