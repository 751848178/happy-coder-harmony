import { Logger, LogTags } from '../utils/Logger';
import pushService from '@ohos.push.pushService';
import notificationManager from '@ohos.notificationManager';
import { PushConnectionStatus, PushEventType, PushMessage, PushMessageType } from './PushPluginModels';
import { PushPluginBase } from './PushPluginBase';

export class PushPluginSupport extends PushPluginBase {
  protected registerPushCallbacks(): void {
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
  protected unregisterPushCallbacks(): void {
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
  protected async getPushToken(): Promise<void> {
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
  protected async createNotificationChannel(): Promise<boolean> {
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
}
