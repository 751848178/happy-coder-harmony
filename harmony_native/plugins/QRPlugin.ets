import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import scanBarcode from '@hms.core.scan.scanBarcode';
import scanCore from '@hms.core.scan.scanCore';
import detectBarcode from '@hms.core.scan.detectBarcode';
import generateBarcode from '@hms.core.scan.generateBarcode';

import { Logger, LogTags } from '../utils/Logger';
import { Conversion } from '../utils/Conversion';

export enum QRErrorCorrectionLevel {
  L = 'L',
  M = 'M',
  Q = 'Q',
  H = 'H'
}

export interface QRStyleConfig {
  size: number;
  margin: number;
  errorCorrectionLevel: QRErrorCorrectionLevel;
  foregroundColor: number;
  backgroundColor: number;
  logo?: string;
}

export interface QRScanConfig {
  enableFlash: boolean;
  enableBeep: boolean;
  scanInterval: number;
  scanTypes: ScanType[];
  supportGallery: boolean;
}

export enum ScanType {
  ALL = scanCore.ScanType.ALL,
  QR_CODE = scanCore.ScanType.QR_CODE,
  BARCODE = scanCore.ScanType.ONE_D_CODE,
  CODE_128 = scanCore.ScanType.CODE128_CODE,
  CODE_39 = scanCore.ScanType.CODE39_CODE,
  CODE_93 = scanCore.ScanType.CODE93_CODE,
  CODABAR = scanCore.ScanType.CODABAR_CODE,
  DATA_MATRIX = scanCore.ScanType.DATAMATRIX_CODE,
  EAN_13 = scanCore.ScanType.EAN13_CODE,
  EAN_8 = scanCore.ScanType.EAN8_CODE,
  ITF_14 = scanCore.ScanType.ITF14_CODE,
  PDF_417 = scanCore.ScanType.PDF417_CODE,
  UPC_A = scanCore.ScanType.UPC_A_CODE,
  UPC_E = scanCore.ScanType.UPC_E_CODE,
}

export interface QRScanResult {
  content: string;
  format: string;
  scanType: ScanType;
  timestamp: number;
  originalValue?: string;
  cornerPoints?: Array<{ x: number; y: number }>;
}

export enum QRScanEventType {
  SCAN_SUCCESS = 'scan_success',
  SCAN_ERROR = 'scan_error',
  CAMERA_PERMISSION_DENIED = 'camera_permission_denied',
  CAMERA_STARTED = 'camera_started',
  CAMERA_STOPPED = 'camera_stopped',
  FLASH_CHANGED = 'flash_changed',
}

export interface QRScanEvent {
  type: QRScanEventType;
  data?: Object;
  error?: string;
}

export interface QREventCallbacks {
  onScanSuccess?: (result: QRScanResult) => void;
  onScanError?: (error: string) => void;
  onCameraStarted?: () => void;
  onCameraStopped?: () => void;
  onFlashChanged?: (enabled: boolean) => void;
}

export class QRPlugin {
  private isScanning = false;
  private currentConfig: QRStyleConfig = this.getDefaultConfig();
  private scanConfig: QRScanConfig = this.getDefaultScanConfig();
  private eventCallbacks: QREventCallbacks = {};
  private abilityContext: common.Context | null = null;
  private eventStream: QRScanEvent[] = [];

  constructor() {
    Logger.debug(LogTags.QR, 'QR Plugin initialized');
  }

  setContext(context: common.Context): void {
    this.abilityContext = context;
  }

  async generate(
    data: string,
    options?: Partial<QRStyleConfig>,
  ): Promise<image.PixelMap | null> {
    const config = { ...this.currentConfig, ...options };
    Logger.info(LogTags.QR, `Generating QR code for ${data.substring(0, 32)}`);
    try {
      return await generateBarcode.createBarcode(data, {
        scanType: scanCore.ScanType.QR_CODE,
        width: config.size,
        height: config.size,
        margin: config.margin,
        pixelMapColor: config.foregroundColor,
        backgroundColor: config.backgroundColor,
        level: this.mapCorrectionLevel(config.errorCorrectionLevel),
      });
    } catch (error) {
      Logger.error(LogTags.QR, 'QR code generation failed', error as Error);
      throw error;
    }
  }

  async generateBase64(
    data: string,
    options?: Partial<QRStyleConfig>,
  ): Promise<string | null> {
    try {
      const pixelMap = await this.generate(data, options);
      if (!pixelMap) {
        return null;
      }
      const imagePackerApi = image.createImagePacker();
      const packed = await imagePackerApi.packing(pixelMap, {
        format: 'image/png',
        quality: 100,
      });
      imagePackerApi.release();
      const bytes = packed instanceof Uint8Array ? packed : new Uint8Array(packed);
      return `data:image/png;base64,${Conversion.uint8ArrayToBase64(bytes)}`;
    } catch (error) {
      Logger.error(LogTags.QR, 'QR code Base64 generation failed', error as Error);
      return null;
    }
  }

  startScanning(options?: Partial<QRScanConfig>): QRScanEvent[] {
    if (this.isScanning) {
      Logger.warn(LogTags.QR, 'Scan request ignored because scanner is busy');
      return this.getEventStream();
    }

    this.scanConfig = { ...this.scanConfig, ...options };
    this.eventStream = [];
    this.isScanning = true;
    this.emitEvent({ type: QRScanEventType.CAMERA_STARTED });
    void this.runNativeScan();
    return this.getEventStream();
  }

  stopScanning(): void {
    if (!this.isScanning) {
      return;
    }
    this.isScanning = false;
    this.emitEvent({ type: QRScanEventType.CAMERA_STOPPED });
  }

  async toggleFlash(enable: boolean): Promise<boolean> {
    this.scanConfig.enableFlash = enable;
    this.emitEvent({
      type: QRScanEventType.FLASH_CHANGED,
      data: { enabled: enable },
    });
    Logger.warn(LogTags.QR, 'System scan UI does not expose runtime flash control');
    return false;
  }

  async scanFromGallery(): Promise<QRScanResult | null> {
    Logger.warn(LogTags.QR, 'scanFromGallery requires the caller to provide an image URI');
    return null;
  }

  async scanImage(imageUri: string): Promise<QRScanResult | null> {
    try {
      const results = await detectBarcode.decode(
        { uri: imageUri },
        this.buildScanOptions(),
      );
      if (!results || results.length === 0) {
        return null;
      }
      return this.mapScanResult(results[0]);
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to scan image', error as Error);
      return null;
    }
  }

  getEventStream(): QRScanEvent[] {
    return [...this.eventStream];
  }

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

  private getDefaultConfig(): QRStyleConfig {
    return {
      size: 300,
      margin: 2,
      errorCorrectionLevel: QRErrorCorrectionLevel.M,
      foregroundColor: 0xff111827,
      backgroundColor: 0xffffffff,
    };
  }

  private getDefaultScanConfig(): QRScanConfig {
    return {
      enableFlash: false,
      enableBeep: true,
      scanInterval: 500,
      scanTypes: [ScanType.QR_CODE],
      supportGallery: true,
    };
  }

  private buildScanOptions(): scanBarcode.ScanOptions {
    const requested = this.scanConfig.scanTypes.filter((type) => type !== ScanType.ALL);
    return {
      scanTypes: requested.length > 0 ? requested : [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: this.scanConfig.supportGallery,
    };
  }

  private async runNativeScan(): Promise<void> {
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

  private mapCorrectionLevel(
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

  private mapScanResult(result: scanBarcode.ScanResult): QRScanResult {
    return {
      content: result.originalValue,
      format: this.getScanTypeName(result.scanType),
      scanType: result.scanType as ScanType,
      timestamp: Date.now(),
      originalValue: result.originalValue,
      cornerPoints: result.cornerPoints?.map((point) => ({
        x: point.x,
        y: point.y,
      })),
    };
  }

  private emitEvent(event: QRScanEvent): void {
    this.eventStream.push(event);
    switch (event.type) {
      case QRScanEventType.SCAN_SUCCESS:
        if (this.eventCallbacks.onScanSuccess && event.data != null) {
          this.eventCallbacks.onScanSuccess(event.data as QRScanResult);
        }
        return;
      case QRScanEventType.SCAN_ERROR:
      case QRScanEventType.CAMERA_PERMISSION_DENIED:
        if (this.eventCallbacks.onScanError) {
          this.eventCallbacks.onScanError(
            event.error ?? '扫码失败',
          );
        }
        return;
      case QRScanEventType.CAMERA_STARTED:
        this.eventCallbacks.onCameraStarted?.();
        return;
      case QRScanEventType.CAMERA_STOPPED:
        this.eventCallbacks.onCameraStopped?.();
        return;
      case QRScanEventType.FLASH_CHANGED:
        this.eventCallbacks.onFlashChanged?.(this.scanConfig.enableFlash);
        return;
    }
  }

  private getScanTypeName(scanType: number): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR_CODE';
      case scanCore.ScanType.CODE128_CODE:
        return 'CODE_128';
      case scanCore.ScanType.CODE39_CODE:
        return 'CODE_39';
      case scanCore.ScanType.CODE93_CODE:
        return 'CODE_93';
      case scanCore.ScanType.CODABAR_CODE:
        return 'CODABAR';
      case scanCore.ScanType.DATAMATRIX_CODE:
        return 'DATA_MATRIX';
      case scanCore.ScanType.EAN13_CODE:
        return 'EAN_13';
      case scanCore.ScanType.EAN8_CODE:
        return 'EAN_8';
      case scanCore.ScanType.ITF14_CODE:
        return 'ITF_14';
      case scanCore.ScanType.PDF417_CODE:
        return 'PDF_417';
      case scanCore.ScanType.UPC_A_CODE:
        return 'UPC_A';
      case scanCore.ScanType.UPC_E_CODE:
        return 'UPC_E';
      case scanCore.ScanType.ONE_D_CODE:
        return 'BARCODE';
      default:
        return 'UNKNOWN';
    }
  }
}

class QRManager {
  private static instance: QRPlugin;

  static getInstance(): QRPlugin {
    if (!QRManager.instance) {
      QRManager.instance = new QRPlugin();
    }
    return QRManager.instance;
  }
}

export const qrPlugin = QRManager.getInstance();
export default QRPlugin;
