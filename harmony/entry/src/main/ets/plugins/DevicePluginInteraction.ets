import { Logger, LogTags } from '../utils/Logger';
import pasteboard from '@ohos.pasteboard';
import geoLocationManager from '@ohos.geoLocationManager';
import { LocationInfo, LocationPriority, LocationRequestConfig, LocationScenario, PermissionType } from './DevicePluginModels';
import { DevicePluginPermissions } from './DevicePluginPermissions';

export class DevicePluginInteraction extends DevicePluginPermissions {
  async setClipboard(text: string): Promise<boolean> {
    Logger.debug(LogTags.DEVICE, `Setting clipboard: ${text.substring(0, 20)}...`);

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await systemPasteboard.setData(pasteData);

      Logger.debug(LogTags.DEVICE, 'Clipboard set successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to set clipboard', error as Error);
      return false;
    }
  }

  /**
   * 获取剪贴板内容
   * @returns 剪贴板文本
   */
  async getClipboard(): Promise<string | null> {
    Logger.debug(LogTags.DEVICE, 'Getting clipboard content');

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = await systemPasteboard.getData();
      const text = pasteData.getPrimaryText();

      Logger.debug(LogTags.DEVICE, `Clipboard content: ${text ? text.substring(0, 20) : '(empty)'}...`);
      return text || null;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get clipboard', error as Error);
      return null;
    }
  }

  /**
   * 清空剪贴板
   * @returns 是否成功
   */
  async clearClipboard(): Promise<boolean> {
    Logger.debug(LogTags.DEVICE, 'Clearing clipboard');

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.clearData();

      Logger.debug(LogTags.DEVICE, 'Clipboard cleared successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to clear clipboard', error as Error);
      return false;
    }
  }

  // ========== 位置信息 ==========

  /**
   * 获取当前位置
   * @param config 定位配置
   * @returns 位置信息
   */
  async getCurrentLocation(config?: LocationRequestConfig): Promise<LocationInfo> {
    Logger.debug(LogTags.DEVICE, 'Getting current location');

    try {
      // 先检查位置权限
      const hasPermission = await this.checkPermission(PermissionType.APPROXIMATELY_LOCATION);
      if (!hasPermission) {
        Logger.warn(LogTags.DEVICE, 'No location permission');
        throw new Error('No location permission');
      }

      const requestConfig: geoLocationManager.LocationRequest = {
        scenario: config?.scenario ?? LocationScenario.DAILY_LIFE_SERVICE,
        priority: config?.priority ?? LocationPriority.FIRST_FIX,
        timeInterval: config?.timeInterval ?? 1,
        distanceInterval: config?.distanceInterval ?? 0,
        maxAccuracy: config?.maxAccuracy ?? 0
      };

      const location = await geoLocationManager.getCurrentLocation(requestConfig);

      const info: LocationInfo = {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude,
        heading: location.direction,
        speed: location.speed,
        timestamp: location.timeStamp
      };

      Logger.debug(LogTags.DEVICE, `Location: ${JSON.stringify(info)}`);
      return info;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get location', error as Error);
      throw error;
    }
  }

  /**
   * 启用连续位置更新
   * @param config 定位配置
   * @param callback 位置更新回调
   */
  async enableLocationUpdates(
    config: LocationRequestConfig,
    callback: (location: LocationInfo) => void
  ): Promise<number> {
    Logger.debug(LogTags.DEVICE, 'Enabling location updates');

    try {
      const requestConfig: geoLocationManager.LocationRequest = {
        scenario: config.scenario ?? LocationScenario.DAILY_LIFE_SERVICE,
        priority: config.priority ?? LocationPriority.FIRST_FIX,
        timeInterval: config.timeInterval ?? 1000,
        distanceInterval: config.distanceInterval ?? 0,
        maxAccuracy: config.maxAccuracy ?? 0
      };

      const callbackId = geoLocationManager.on('locationChange', requestConfig, (location) => {
        const info: LocationInfo = {
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          altitude: location.altitude,
          heading: location.direction,
          speed: location.speed,
          timestamp: location.timeStamp
        };
        callback(info);
      });

      Logger.info(LogTags.DEVICE, `Location updates enabled, callbackId: ${callbackId}`);
      return callbackId;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to enable location updates', error as Error);
      throw error;
    }
  }

  /**
   * 禁用连续位置更新
   * @param callbackId 回调 ID
   */
  disableLocationUpdates(callbackId: number): void {
    Logger.debug(LogTags.DEVICE, `Disabling location updates: ${callbackId}`);

    try {
      geoLocationManager.off('locationChange', callbackId);
      Logger.info(LogTags.DEVICE, 'Location updates disabled');
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to disable location updates', error as Error);
    }
  }

  // ========== 工具方法 ==========

  /**
   * 测试通道是否可用
   */
  async ping(): Promise<boolean> {
}
