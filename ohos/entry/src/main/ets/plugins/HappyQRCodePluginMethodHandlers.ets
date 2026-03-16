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

import { FlashChangedData, QrEventPayload, TAG } from './HappyQRCodePluginModels';
import { HappyQRCodePluginScanSupport } from './HappyQRCodePluginScanSupport';

export class HappyQRCodePluginMethodHandlers extends HappyQRCodePluginScanSupport {
  protected handleGenerate(call: MethodCall, result: MethodResult): void {
    const args = this.asArgsMap(call.args);
    const payload = this.readString(args, 'data');
    if (payload == null || payload.length === 0) {
      result.error('invalid-args', '缺少二维码内容', null);
      return;
    }
    const size = this.readNumber(args, 'size') ?? 220;
    void this.generateBase64(payload, size)
      .then((value) => result.success(value))
      .catch((error: Error) => {
        Log.e(TAG, 'Failed to generate QR code', error);
        result.error('generate-failed', error.message, null);
      });
  }

  protected handleRequestCameraPermission(result: MethodResult): void {
    void this.requestCameraPermission()
      .then((granted) => result.success(granted))
      .catch((error: Error) => {
        Log.e(TAG, 'Failed to request camera permission', error);
        result.error('permission-failed', error.message, null);
      });
  }

  protected handleCheckCameraPermission(result: MethodResult): void {
    void this.checkCameraPermission()
      .then((granted) => result.success(granted))
      .catch((error: Error) => {
        Log.e(TAG, 'Failed to check camera permission', error);
        result.error('permission-check-failed', error.message, null);
      });
  }

  protected handleStartScan(call: MethodCall, result: MethodResult): void {
    if (this.abilityContext == null) {
      result.error('no-ability', '当前无法启动扫码能力', null);
      return;
    }
    const args = this.asArgsMap(call.args);
    const scanTypes = this.readScanTypes(args);
    const supportGallery = this.readBool(args, 'supportGallery') ?? true;
    this.flashEnabled = this.readBool(args, 'enableFlash') ?? false;
    this.isScanning = true;
    const startedEvent: QrEventPayload = {
      type: 'camera_started',
    };
    this.emitEvent(startedEvent);
    void this.runNativeScan(scanTypes, supportGallery);
    result.success(true);
  }

  protected handleToggleFlash(call: MethodCall, result: MethodResult): void {
    const args = this.asArgsMap(call.args);
    this.flashEnabled = this.readBool(args, 'enabled') ?? false;
    const flashData: FlashChangedData = {
      enabled: this.flashEnabled,
    };
    const flashEvent: QrEventPayload = {
      type: 'flash_changed',
      data: flashData,
    };
    this.emitEvent(flashEvent);
    result.success(false);
  }
}
