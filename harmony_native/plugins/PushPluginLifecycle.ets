import { Logger, LogTags } from '../utils/Logger';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { PushConnectionStatus, PushEvent, PushEventCallbacks, PushPermissionStatus } from './PushPluginModels';
import { PushPluginEvents } from './PushPluginEvents';

export class PushPluginLifecycle extends PushPluginEvents {
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
}
