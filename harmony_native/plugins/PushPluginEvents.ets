import { Logger, LogTags } from '../utils/Logger';
import pushService from '@ohos.push.pushService';
import { PushConnectionStatus, PushEvent, PushEventType, PushMessage, PushMessageType } from './PushPluginModels';
import { PushPluginSupport } from './PushPluginSupport';

export class PushPluginEvents extends PushPluginSupport {
  protected parsePushMessage(message: pushService.PushMessage): PushMessage {
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
  protected determineMessageType(data: Record<string, string>): PushMessageType {
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
  protected notifyTokenRefresh(token: string): void {
    if (this.eventCallbacks.onTokenRefresh) {
      this.eventCallbacks.onTokenRefresh(token);
    }
  }

  /**
   * 通知收到消息
   */
  protected notifyMessageReceived(message: PushMessage): void {
    if (this.eventCallbacks.onMessageReceived) {
      this.eventCallbacks.onMessageReceived(message);
    }
  }

  /**
   * 通知消息被点击
   */
  protected notifyMessageClicked(message: PushMessage): void {
    if (this.eventCallbacks.onMessageClicked) {
      this.eventCallbacks.onMessageClicked(message);
    }
  }

  /**
   * 通知错误
   */
  protected notifyError(error: string): void {
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
  protected notifyConnected(): void {
    if (this.eventCallbacks.onConnected) {
      this.eventCallbacks.onConnected();
    }
  }

  /**
   * 通知已断开
   */
  protected notifyDisconnected(): void {
    if (this.eventCallbacks.onDisconnected) {
      this.eventCallbacks.onDisconnected();
    }
  }

  /**
   * 清理资源
   */
}
