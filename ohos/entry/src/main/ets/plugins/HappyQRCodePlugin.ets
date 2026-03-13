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

const TAG = 'HappyQRCodePlugin';
const METHOD_CHANNEL = 'happy.qrcode';
const EVENT_CHANNEL = 'happy.qrcode/events';

interface FlashChangedData {
  enabled: boolean;
}

interface QrPoint {
  x: number;
  y: number;
}

interface ScanSuccessData {
  content: string;
  format: string;
  scanType: scanCore.ScanType;
  timestamp: number;
  originalValue: string;
  cornerPoints?: Array<QrPoint>;
}

interface QrEventPayload {
  type: string;
  data?: FlashChangedData | ScanSuccessData;
  error?: string;
}

interface BarcodeCreateOptions {
  scanType: scanCore.ScanType;
  width: number;
  height: number;
  margin: number;
  pixelMapColor: number;
  backgroundColor: number;
  level: generateBarcode.ErrorCorrectionLevel;
}

interface ImagePackOptions {
  format: string;
  quality: number;
}

interface ScanOptionsPayload {
  scanTypes: Array<scanCore.ScanType>;
  enableMultiMode: boolean;
  enableAlbum: boolean;
}

interface PermissionRequestResponse {
  authResults: Array<number>;
}

export default class HappyQRCodePlugin implements
  FlutterPlugin,
  AbilityAware,
  MethodCallHandler,
  StreamHandler {
  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private abilityContext: common.UIAbilityContext | null = null;
  private readonly base64Helper = new util.Base64Helper();
  private isScanning = false;
  private flashEnabled = false;

  getUniqueClassName(): string {
    return 'HappyQRCodePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      METHOD_CHANNEL,
    );
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(
      binding.getBinaryMessenger(),
      EVENT_CHANNEL,
    );
    this.eventChannel.setStreamHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
    this.eventChannel = null;
    this.eventSink = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityContext = binding.getAbility().context as common.UIAbilityContext;
  }

  onDetachedFromAbility(): void {
    this.abilityContext = null;
  }

  onListen(args: Object | null, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: Object | null): void {
    this.eventSink = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'ping':
        result.success(true);
        return;
      case 'generate':
        this.handleGenerate(call, result);
        return;
      case 'requestCameraPermission':
        this.handleRequestCameraPermission(result);
        return;
      case 'checkCameraPermission':
        this.handleCheckCameraPermission(result);
        return;
      case 'startScan':
        this.handleStartScan(call, result);
        return;
      case 'stopScan':
        this.stopScan();
        result.success(true);
        return;
      case 'toggleFlash':
        this.handleToggleFlash(call, result);
        return;
      default:
        result.notImplemented();
        return;
    }
  }

  private handleGenerate(call: MethodCall, result: MethodResult): void {
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

  private handleRequestCameraPermission(result: MethodResult): void {
    void this.requestCameraPermission()
      .then((granted) => result.success(granted))
      .catch((error: Error) => {
        Log.e(TAG, 'Failed to request camera permission', error);
        result.error('permission-failed', error.message, null);
      });
  }

  private handleCheckCameraPermission(result: MethodResult): void {
    void this.checkCameraPermission()
      .then((granted) => result.success(granted))
      .catch((error: Error) => {
        Log.e(TAG, 'Failed to check camera permission', error);
        result.error('permission-check-failed', error.message, null);
      });
  }

  private handleStartScan(call: MethodCall, result: MethodResult): void {
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

  private handleToggleFlash(call: MethodCall, result: MethodResult): void {
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

  private emitEvent(event: QrEventPayload): void {
    if (this.eventSink == null) {
      return;
    }
    this.eventSink.success(event);
  }

  private stopScan(): void {
    if (!this.isScanning) {
      return;
    }
    this.isScanning = false;
    const stoppedEvent: QrEventPayload = {
      type: 'camera_stopped',
    };
    this.emitEvent(stoppedEvent);
  }

  private async generateBase64(data: string, size: number): Promise<string | null> {
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

  private async checkCameraPermission(): Promise<boolean> {
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

  private async requestCameraPermission(): Promise<boolean> {
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

  private async runNativeScan(
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
      const result = await scanBarcode.startScanForResult(this.abilityContext, scanOptions);
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
      const cornerPoints = result.cornerPoints?.map((point): QrPoint => {
        const mappedPoint: QrPoint = {
          x: point.x,
          y: point.y,
        };
        return mappedPoint;
      });
      const successData: ScanSuccessData = {
        content: result.originalValue,
        format: this.getScanTypeName(result.scanType),
        scanType: result.scanType,
        timestamp: Date.now(),
        originalValue: result.originalValue,
        cornerPoints: cornerPoints,
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

  private asArgsMap(
    value: Object | null,
  ): Map<string, Object> | null {
    if (value == null || !(value instanceof Map)) {
      return null;
    }
    return value as Map<string, Object>;
  }

  private readString(
    args: Map<string, Object> | null,
    key: string,
  ): string | null {
    if (args == null || !args.has(key)) {
      return null;
    }
    const value = args.get(key);
    return typeof value === 'string' ? value.trim() : null;
  }

  private readBool(
    args: Map<string, Object> | null,
    key: string,
  ): boolean | null {
    if (args == null || !args.has(key)) {
      return null;
    }
    const value = args.get(key);
    return typeof value === 'boolean' ? value : null;
  }

  private readNumber(
    args: Map<string, Object> | null,
    key: string,
  ): number | null {
    if (args == null || !args.has(key)) {
      return null;
    }
    const value = args.get(key);
    return typeof value === 'number' ? value : null;
  }

  private readScanTypes(args: Map<string, Object> | null): Array<scanCore.ScanType> {
    if (args == null || !args.has('scanTypes')) {
      return [scanCore.ScanType.QR_CODE];
    }
    const value = args.get('scanTypes');
    if (!(value instanceof Array) || value.length === 0) {
      return [scanCore.ScanType.QR_CODE];
    }
    const types: Array<scanCore.ScanType> = [];
    for (const item of value as Array<Object>) {
      if (typeof item === 'number') {
        types.push(item as scanCore.ScanType);
      }
    }
    return types.length > 0 ? types : [scanCore.ScanType.QR_CODE];
  }

  private getScanTypeName(type: scanCore.ScanType): string {
    switch (type) {
      case scanCore.ScanType.ONE_D_CODE:
        return 'barcode';
      case scanCore.ScanType.CODE128_CODE:
        return 'code128';
      case scanCore.ScanType.CODE39_CODE:
        return 'code39';
      case scanCore.ScanType.CODE93_CODE:
        return 'code93';
      case scanCore.ScanType.CODABAR_CODE:
        return 'codabar';
      case scanCore.ScanType.DATAMATRIX_CODE:
        return 'datamatrix';
      case scanCore.ScanType.EAN13_CODE:
        return 'ean13';
      case scanCore.ScanType.EAN8_CODE:
        return 'ean8';
      case scanCore.ScanType.ITF14_CODE:
        return 'itf14';
      case scanCore.ScanType.PDF417_CODE:
        return 'pdf417';
      case scanCore.ScanType.UPC_A_CODE:
        return 'upc_a';
      case scanCore.ScanType.UPC_E_CODE:
        return 'upc_e';
      case scanCore.ScanType.QR_CODE:
      default:
        return 'qr';
    }
  }
}
