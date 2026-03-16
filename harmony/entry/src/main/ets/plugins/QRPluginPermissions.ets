import { Logger, LogTags } from '../utils/Logger';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { QREventCallbacks, QRScanEvent, QRScanResult } from './QRPluginModels';
import { QRPluginScan } from './QRPluginScan';

export class QRPluginPermissions extends QRPluginScan {
  getEventStream(): QRScanEvent[] {
    return [...this.eventStream];
  }

  /**
   * 设置事件回调
   * @param callbacks 事件回调对象
   */
  setEventCallbacks(callbacks: QREventCallbacks): void {
    this.eventCallbacks = { ...this.eventCallbacks, ...callbacks };
    Logger.debug(LogTags.QR, 'Event callbacks updated');
  }

  /**
   * 检查相机权限
   * @returns 是否有相机权限
   */
  async checkCameraPermission(): Promise<boolean> {
    if (!this.abilityContext) {
      Logger.error(LogTags.QR, 'Ability context not set');
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const status = await atManager.checkAccessToken(
        this.abilityContext.applicationInfo.accessTokenId,
        'ohos.permission.CAMERA'
      );
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to check camera permission', error as Error);
      return false;
    }
  }

  /**
   * 请求相机权限
   * @returns 是否获得权限
   */
  async requestCameraPermission(): Promise<boolean> {
    Logger.info(LogTags.QR, 'Requesting camera permission');

    if (!this.abilityContext) {
      Logger.error(LogTags.QR, 'Ability context not set');
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const result = await atManager.requestPermissionsFromUser(
        this.abilityContext,
        ['ohos.permission.CAMERA']
      );

      const granted = result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      if (!granted) {
        this.eventStream.push({
          type: QRScanEventType.CAMERA_PERMISSION_DENIED
        });
      }

      Logger.info(LogTags.QR, `Camera permission ${granted ? 'granted' : 'denied'}`);
      return granted;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to request camera permission', error as Error);
      return false;
    }
  }

  /**
   * 检查扫描状态
   * @returns 是否正在扫描
   */
  isScanningActive(): boolean {
    return this.isScanning;
  }

  /**
   * 测试通道是否可用
   * @returns 始终返回 true
   */
  async ping(): Promise<boolean> {
}
