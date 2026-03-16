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

export const TAG = 'HappyQRCodePlugin';
export const METHOD_CHANNEL = 'happy.qrcode';
export const EVENT_CHANNEL = 'happy.qrcode/events';

export interface FlashChangedData {
  enabled: boolean;
}

export interface QrPoint {
  x: number;
  y: number;
}

export interface ScanSuccessData {
  content: string;
  format: string;
  scanType: scanCore.ScanType;
  timestamp: number;
  originalValue: string;
  cornerPoints?: Array<QrPoint>;
}

export interface QrEventPayload {
  type: string;
  data?: FlashChangedData | ScanSuccessData;
  error?: string;
}

export interface BarcodeCreateOptions {
  scanType: scanCore.ScanType;
  width: number;
  height: number;
  margin: number;
  pixelMapColor: number;
  backgroundColor: number;
  level: generateBarcode.ErrorCorrectionLevel;
}

export interface ImagePackOptions {
  format: string;
  quality: number;
}

export interface ScanOptionsPayload {
  scanTypes: Array<scanCore.ScanType>;
  enableMultiMode: boolean;
  enableAlbum: boolean;
}

export interface PermissionRequestResponse {
  authResults: Array<number>;
}
