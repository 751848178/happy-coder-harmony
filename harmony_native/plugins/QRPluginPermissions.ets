import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { Logger, LogTags } from '../utils/Logger';
import { QREventCallbacks } from './QRPluginModels';
import { QRPluginScan } from './QRPluginScan';

export class QRPluginPermissions extends QRPluginScan {
  setEventCallbacks(callbacks: QREventCallbacks): void {
    this.eventCallbacks = { ...this.eventCallbacks, ...callbacks };
  }

  async checkCameraPermission(): Promise<boolean> {
    if (!this.abilityContext) {
      return false;
    }
    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const status = await atManager.checkAccessToken(
        this.abilityContext.applicationInfo.accessTokenId,
        'ohos.permission.CAMERA',
      );
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to check camera permission', error as Error);
      return false;
    }
  }

  async requestCameraPermission(): Promise<boolean> {
    if (!this.abilityContext) {
      return false;
    }
    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const response = await atManager.requestPermissionsFromUser(
        this.abilityContext,
        ['ohos.permission.CAMERA'],
      );
      const granted =
        response.authResults.length > 0 &&
        response.authResults[0] ===
          abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      if (!granted) {
        this.emitEvent({ type: QRScanEventType.CAMERA_PERMISSION_DENIED });
      }
      return granted;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to request camera permission', error as Error);
      this.emitEvent({
        type: QRScanEventType.SCAN_ERROR,
        error: (error as Error).message,
      });
      return false;
    }
  }

  isScanningActive(): boolean {
    return this.isScanning;
  }

  async ping(): Promise<boolean> {
    return true;
  }

  dispose(): void {
    this.stopScanning();
    this.eventStream = [];
  }
}
