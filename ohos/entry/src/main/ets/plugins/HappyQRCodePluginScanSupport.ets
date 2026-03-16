import {
  AbilityAware,
  AbilityPluginBinding,
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import image from '@ohos.multimedia.image';
import util from '@ohos.util';
import scanBarcode from '@hms.core.scan.scanBarcode';
import scanCore from '@hms.core.scan.scanCore';
import generateBarcode from '@hms.core.scan.generateBarcode';

import { BarcodeCreateOptions, ImagePackOptions, PermissionRequestResponse, QrEventPayload, QrPoint, ScanOptionsPayload, ScanSuccessData, TAG } from './HappyQRCodePluginModels';
import { HappyQRCodePluginBase } from './HappyQRCodePluginBase';

export class HappyQRCodePluginScanSupport extends HappyQRCodePluginBase {
  protected emitEvent(event: QrEventPayload): void {
    if (this.eventSink == null) {
      return;
    }
    this.eventSink.success(event);
  }

  protected stopScan(): void {
    if (!this.isScanning) {
      return;
    }
    this.isScanning = false;
    const stoppedEvent: QrEventPayload = {
      type: 'camera_stopped',
    };
    this.emitEvent(stoppedEvent);
  }

  protected async generateBase64(data: string, size: number): Promise<string | null> {
    const barcodeOptions: BarcodeCreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      width: size,
      height: size,
      margin: 2,
      pixelMapColor: 0xff111827,
      backgroundColor: 0xffffffff,
      level: generateBarcode.ErrorCorrectionLevel.LEVEL_M,
    };
    const pixelMap = await generateBarcode.createBarcode(data, barcodeOptions);
    const imagePacker = image.createImagePacker();
    try {
      const packOptions: ImagePackOptions = {
        format: 'image/png',
        quality: 100,
      };
      const packed = await imagePacker.packing(pixelMap, packOptions);
      const bytes = packed instanceof Uint8Array
        ? packed
        : new Uint8Array(packed as ArrayBuffer);
      return `data:image/png;base64,${this.base64Helper.encodeToStringSync(bytes)}`;
    } finally {
      imagePacker.release();
    }
  }

  protected async checkCameraPermission(): Promise<boolean> {
    if (this.abilityContext == null) {
      return false;
    }
    const atManager = abilityAccessCtrl.createAtManager();
    const status = await atManager.verifyAccessToken(
      this.abilityContext.applicationInfo.accessTokenId,
      'ohos.permission.CAMERA',
    );
    return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  protected async requestCameraPermission(): Promise<boolean> {
    if (this.abilityContext == null) {
      return false;
    }
    const atManager = abilityAccessCtrl.createAtManager();
    const response = await atManager.requestPermissionsFromUser(
      this.abilityContext,
      ['ohos.permission.CAMERA'],
    ) as PermissionRequestResponse;
    const granted =
      response.authResults.length > 0 &&
      response.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    if (!granted) {
      const deniedEvent: QrEventPayload = {
        type: 'scan_error',
        error: '未授予相机权限',
      };
      this.emitEvent(deniedEvent);
    }
    return granted;
  }

  protected async runNativeScan(
    scanTypes: Array<scanCore.ScanType>,
    supportGallery: boolean,
  ): Promise<void> {
    try {
      if (this.abilityContext == null) {
        throw new Error('当前无法获取扫码上下文');
      }
      const hasPermission =
        (await this.checkCameraPermission()) ||
        (await this.requestCameraPermission());
      if (!hasPermission) {
        this.stopScan();
        return;
      }
      const scanOptions: ScanOptionsPayload = {
        scanTypes: scanTypes.length > 0 ? scanTypes : [scanCore.ScanType.QR_CODE],
        enableMultiMode: false,
        enableAlbum: supportGallery,
      };
      const result = await scanBarcode.startScanForResult(
        this.abilityContext,
        scanOptions,
      ) as scanBarcode.ScanResult;
      if (!this.isScanning) {
        return;
      }
      if (!result.originalValue || result.originalValue.trim().length === 0) {
        const emptyEvent: QrEventPayload = {
          type: 'scan_error',
          error: '未识别到二维码内容',
        };
        this.emitEvent(emptyEvent);
        return;
      }
      const cornerPoints: Array<QrPoint> = [];
      if (result.cornerPoints != null) {
        for (const point of result.cornerPoints as Array<QrPoint>) {
          cornerPoints.push({
            x: point.x,
            y: point.y,
          });
        }
      }
      const successData: ScanSuccessData = {
        content: result.originalValue,
        format: this.getScanTypeName(result.scanType),
        scanType: result.scanType,
        timestamp: Date.now(),
        originalValue: result.originalValue,
        cornerPoints: cornerPoints.length > 0 ? cornerPoints : undefined,
      };
      const successEvent: QrEventPayload = {
        type: 'scan_success',
        data: successData,
      };
      this.emitEvent(successEvent);
    } catch (error) {
      const message = (error as Error).message ?? '扫码失败';
      Log.e(TAG, 'Native scan failed', error as Error);
      const errorEvent: QrEventPayload = {
        type: 'scan_error',
        error: message,
      };
      this.emitEvent(errorEvent);
    } finally {
      this.stopScan();
    }
  }
}
