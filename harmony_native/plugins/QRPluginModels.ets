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
