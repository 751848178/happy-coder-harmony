// QR Plugin
//
// QR 码生成与扫描插件
//
// 功能：
// - 生成 QR 码图片
// - 扫描 QR 码
// - 自定义 QR 码样式
// - 处理扫描结果

import { Logger, LogTags } from '../utils/Logger';
import scanBarcode from '@ohos.multimedia.scanBarcode';
import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

/**
 * QR 码纠错级别
 */
export enum QRErrorCorrectionLevel {
  L = 'L',  // ~7% 容错
  M = 'M',  // ~15% 容错
  Q = 'Q',  // ~25% 容错
  H = 'H'   // ~30% 容错
}

/**
 * QR 码样式配置
 */
export interface QRStyleConfig {
  size: number;                    // 图片尺寸 (像素)
  margin: number;                  // 边距
  errorCorrectionLevel: QRErrorCorrectionLevel;
  foregroundColor: number;         // 前景色 (ARGB)
  backgroundColor: number;         // 背景色 (ARGB)
  logo?: string;                   // Logo 图片 URI
}

/**
 * 扫描配置
 */
export interface QRScanConfig {
  enableFlash: boolean;            // 是否启用闪光灯
  enableBeep: boolean;             // 扫描成功是否播放提示音
  scanInterval: number;            // 扫描间隔 (毫秒)
  scanTypes: ScanType[];           // 扫描类型
  supportGallery: boolean;         // 是否支持从相册选择
}

/**
 * 扫描类型
 */
export enum ScanType {
  ALL = 0,
  QR_CODE = scanBarcode.ScanType.SCAN_TYPE_QR_CODE,
  BARCODE = scanBarcode.ScanType.SCAN_TYPE_BARCODE,
  CODE_128 = scanBarcode.ScanType.SCAN_TYPE_CODE_128,
  CODE_39 = scanBarcode.ScanType.SCAN_TYPE_CODE_39,
  CODE_93 = scanBarcode.ScanType.SCAN_TYPE_CODE_93,
  CODE_93 = scanBarcode.ScanType.SCAN_TYPE_CODE_93,
  CODABAR = scanBarcode.ScanType.SCAN_TYPE_CODABAR,
  DATA_MATRIX = scanBarcode.ScanType.SCAN_TYPE_DATA_MATRIX,
  EAN_13 = scanBarcode.ScanType.SCAN_TYPE_EAN_13,
  EAN_8 = scanBarcode.ScanType.SCAN_TYPE_EAN_8,
  ITF_14 = scanBarcode.ScanType.SCAN_TYPE_ITF_14,
  PDF_417 = scanBarcode.ScanType.SCAN_TYPE_PDF_417,
  UPC_A = scanBarcode.ScanType.SCAN_TYPE_UPC_A,
  UPC_E = scanBarcode.ScanType.SCAN_TYPE_UPC_E
}

/**
 * 扫描结果
 */
export interface QRScanResult {
  content: string;                 // QR 码内容
  format: string;                  // 码制格式
  scanType: ScanType;              // 扫描类型
  timestamp: number;               // 扫描时间戳
  originalValue?: string;          // 原始值
  cornerPoints?: Array<{x: number, y: number}>;  // 角点坐标
}

/**
 * QR 扫描事件
 */
export enum QRScanEventType {
  SCAN_SUCCESS = 'scan_success',
  SCAN_ERROR = 'scan_error',
  CAMERA_PERMISSION_DENIED = 'camera_permission_denied',
  CAMERA_STARTED = 'camera_started',
  CAMERA_STOPPED = 'camera_stopped',
  FLASH_CHANGED = 'flash_changed'
}

/**
 * QR 扫描事件
 */
export interface QRScanEvent {
  type: QRScanEventType;
  data?: any;
  error?: string;
}

/**
 * QR 事件回调
 */
export interface QREventCallbacks {
  onScanSuccess?: (result: QRScanResult) => void;
  onScanError?: (error: string) => void;
  onCameraStarted?: () => void;
  onCameraStopped?: () => void;
  onFlashChanged?: (enabled: boolean) => void;
}

/**
 * QR Plugin 类
 */
