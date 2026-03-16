import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import scanBarcode from '@hms.core.scan.scanBarcode';
import scanCore from '@hms.core.scan.scanCore';
import detectBarcode from '@hms.core.scan.detectBarcode';
import generateBarcode from '@hms.core.scan.generateBarcode';
import { Logger, LogTags } from '../utils/Logger';
import { Conversion } from '../utils/Conversion';
import { QRScanConfig, QRStyleConfig } from './QRPluginModels';

export class QRPluginBase {
  protected isScanning = false;
  protected currentConfig: QRStyleConfig = this.getDefaultConfig();
  protected scanConfig: QRScanConfig = this.getDefaultScanConfig();
  protected eventCallbacks: QREventCallbacks = {};
  protected abilityContext: common.Context | null = null;
  protected eventStream: QRScanEvent[] = [];

  constructor() {
    Logger.debug(LogTags.QR, 'QR Plugin initialized');
  }

  setContext(context: common.Context): void {
  protected getDefaultConfig(): QRStyleConfig {
    return {
      size: 300,
      margin: 2,
      errorCorrectionLevel: QRErrorCorrectionLevel.M,
      foregroundColor: 0xff111827,
      backgroundColor: 0xffffffff,
    };
  }

  protected getDefaultScanConfig(): QRScanConfig {
    return {
      enableFlash: false,
      enableBeep: true,
      scanInterval: 500,
      scanTypes: [ScanType.QR_CODE],
      supportGallery: true,
    };
  }

  protected buildScanOptions(): scanBarcode.ScanOptions {
    const requested = this.scanConfig.scanTypes.filter((type) => type !== ScanType.ALL);
    return {
      scanTypes: requested.length > 0 ? requested : [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: this.scanConfig.supportGallery,
    };
  }

  protected async runNativeScan(): Promise<void> {
    try {
      if (!this.abilityContext) {
        throw new Error('Ability context not set');
      }

      const hasPermission =
        (await this.checkCameraPermission()) ||
        (await this.requestCameraPermission());
      if (!hasPermission) {
        this.isScanning = false;
        return;
      }

      const result = await scanBarcode.startScanForResult(
        this.abilityContext,
        this.buildScanOptions(),
      );
      if (!this.isScanning) {
        return;
      }
      if (!result || !result.originalValue || result.originalValue.trim().length === 0) {
        this.emitEvent({
          type: QRScanEventType.SCAN_ERROR,
          error: '未识别到二维码内容',
        });
        return;
      }

      const mapped = this.mapScanResult(result);
      this.emitEvent({
        type: QRScanEventType.SCAN_SUCCESS,
        data: mapped as Object,
      });
    } catch (error) {
      const message = (error as Error).message ?? '扫码失败';
      Logger.error(LogTags.QR, 'Native scan failed', error as Error);
      this.emitEvent({
        type: QRScanEventType.SCAN_ERROR,
        error: message,
      });
    } finally {
      if (this.isScanning) {
        this.isScanning = false;
        this.emitEvent({ type: QRScanEventType.CAMERA_STOPPED });
      }
    }
  }

  protected mapCorrectionLevel(
    level: QRErrorCorrectionLevel,
  ): generateBarcode.ErrorCorrectionLevel {
    switch (level) {
      case QRErrorCorrectionLevel.L:
        return generateBarcode.ErrorCorrectionLevel.LEVEL_L;
      case QRErrorCorrectionLevel.Q:
        return generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
      case QRErrorCorrectionLevel.H:
        return generateBarcode.ErrorCorrectionLevel.LEVEL_H;
      case QRErrorCorrectionLevel.M:
      default:
        return generateBarcode.ErrorCorrectionLevel.LEVEL_M;
    }
  }
}
