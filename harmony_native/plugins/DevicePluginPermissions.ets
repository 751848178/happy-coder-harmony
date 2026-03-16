import { Logger, LogTags } from '../utils/Logger';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { PermissionStatus, PermissionType } from './DevicePluginModels';
import { DevicePluginPower } from './DevicePluginPower';

export class DevicePluginPermissions extends DevicePluginPower {
  async requestCameraPermission(): Promise<boolean> {
    return this.requestPermission(PermissionType.CAMERA);
  }

  /**
   * 请求麦克风权限
   * @returns 是否获得权限
   */
  async requestMicrophonePermission(): Promise<boolean> {
    return this.requestPermission(PermissionType.MICROPHONE);
  }

  /**
   * 请求存储权限（使用媒体权限）
   * @returns 是否获得权限
   */
  async requestStoragePermission(): Promise<boolean> {
    // 鸿蒙 NEXT 不再需要存储权限，改用媒体权限
    return await this.requestPermission(PermissionType.READ_MEDIA_IMAGE);
  }

  /**
   * 请求位置权限
   * @returns 是否获得权限
   */
  async requestLocationPermission(): Promise<boolean> {
    // 先请求大概位置权限
    const approxResult = await this.requestPermission(PermissionType.APPROXIMATELY_LOCATION);
    return approxResult;
  }

  /**
   * 请求多个权限
   * @param permissions 权限列表
   * @returns 权限状态映射
   */
  async requestMultiplePermissions(permissions: PermissionType[]): Promise<Map<PermissionType, boolean>> {
    Logger.info(LogTags.DEVICE, `Requesting ${permissions.length} permissions`);

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      const resultMap = new Map<PermissionType, boolean>();
      permissions.forEach(perm => resultMap.set(perm, false));
      return resultMap;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const results = await atManager.requestPermissionsFromUser(this.abilityContext, permissions);

      const resultMap = new Map<PermissionType, boolean>();
      permissions.forEach((perm, index) => {
        const granted = results.authResults[index] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        resultMap.set(perm, granted);
        Logger.debug(LogTags.DEVICE, `Permission ${perm}: ${granted ? 'granted' : 'denied'}`);
      });

      return resultMap;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to request permissions', error as Error);
      const resultMap = new Map<PermissionType, boolean>();
      permissions.forEach(perm => resultMap.set(perm, false));
      return resultMap;
    }
  }

  /**
   * 检查权限状态
   * @param permission 权限类型
   * @returns 权限状态
   */
  async checkPermission(permission: PermissionType): Promise<PermissionStatus> {
    Logger.debug(LogTags.DEVICE, `Checking permission: ${permission}`);

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      return PermissionStatus.NOT_DETERMINED;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const status = await atManager.checkAccessToken(this.abilityContext.applicationInfo.accessTokenId, permission);

      const permissionStatus = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        ? PermissionStatus.GRANTED
        : PermissionStatus.DENIED;

      Logger.debug(LogTags.DEVICE, `Permission ${permission} status: ${permissionStatus}`);
      return permissionStatus;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to check permission', error as Error);
      return PermissionStatus.NOT_DETERMINED;
    }
  }

  /**
   * 打开应用设置页面
   */
  async openAppSettings(): Promise<void> {
    Logger.info(LogTags.DEVICE, 'Opening app settings');

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      throw new Error('Ability context not set');
    }

    try {
      const bundleInfo = await this.abilityContext.bundleManager.getBundleInfoForSelf(
        this.abilityContext.bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );

      const want: Want = {
        bundleName: bundleInfo.appInfo.name,
        abilityName: 'com.huawei.settings.MainAbility'
      };

      await this.abilityContext.startAbility(want);
      Logger.debug(LogTags.DEVICE, 'App settings opened');
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to open app settings', error as Error);
      // 备选方案：打开通用设置
      try {
        const want: Want = {
          bundleName: 'com.huawei.settings',
          abilityName: 'com.huawei.settings.MainAbility'
        };
        await this.abilityContext.startAbility(want);
      } catch (e) {
        Logger.error(LogTags.DEVICE, 'Failed to open settings', e as Error);
        throw new Error('Unable to open settings');
      }
    }
  }
}
