import { Logger, LogTags } from '../utils/Logger';
import notificationManager from '@ohos.notificationManager';
import { PushNotificationConfig } from './PushPluginModels';
import { PushPluginLifecycle } from './PushPluginLifecycle';

export class PushPluginNotification extends PushPluginLifecycle {
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
}
