import { Logger, LogTags } from '../utils/Logger';
import common from '@ohos.app.ability.common';
import pushService from '@ohos.push.pushService';
import notificationManager from '@ohos.notificationManager';
import { PushConnectionStatus, PushEvent, PushEventCallbacks, PushNotificationConfig, PushPermissionStatus } from './PushPluginModels';

export class PushPluginBase {
  protected isInitialized: boolean = false;
  protected currentToken: string = '';
  protected permissionStatus: PushPermissionStatus = PushPermissionStatus.NOT_DETERMINED;
  protected initialMessage: PushMessage | null = null;
  protected eventCallbacks: PushEventCallbacks = {};

  // Push Kit 相关
  protected abilityContext: common.Context | null = null;
  protected pushService: pushService.PushService | null = null;
  protected connectionStatus: PushConnectionStatus = PushConnectionStatus.DISCONNECTED;

  // 通知配置
  protected notificationConfig: PushNotificationConfig = {
    channelId: 'happy_coder_channel',
    channelName: 'Happy Coder',
    enableVibrate: true,
    enableLight: true,
    enableSound: true,
    importance: 4
  };

  // 事件流
  protected eventStream: PushEvent[] = [];

  constructor() {
    Logger.debug(LogTags.PUSH, 'Push Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
}
