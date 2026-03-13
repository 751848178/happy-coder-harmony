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
export class QRPlugin {
  private isScanning: boolean = false;
  private currentConfig: QRStyleConfig = this.getDefaultConfig();
  private scanConfig: QRScanConfig = this.getDefaultScanConfig();
  private eventCallbacks: QREventCallbacks = {};

  // 扫描相关
  private abilityContext: common.Context | null = null;
  private scanBarcodeInstance: scanBarcode.ScanBarcode | null = null;
  private scanCallback: ((result: Array<scanBarcode.ScanResult>) => void) | null = null;

  // 事件流
  private eventStream: QRScanEvent[] = [];

  constructor() {
    Logger.debug(LogTags.QR, 'QR Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
    this.abilityContext = context;
  }

  // ========== 公共方法 ==========

  /**
   * 生成 QR 码
   * @param data QR 码内容
   * @param options 可选配置
   * @returns QR 码图片的 PixelMap
   */
  async generate(data: string, options?: Partial<QRStyleConfig>): Promise<image.PixelMap | null> {
    Logger.info(LogTags.QR, `Generating QR code for: ${data.substring(0, 30)}...`);

    try {
      // 合并配置
      const config = { ...this.currentConfig, ...options };

      // 使用 ImagePacker 生成 QR 码
      // 注意：HarmonyOS 需要使用第三方 QR 码生成库
      // 以下是简化实现，返回一个占位图片

      const pixelMap = await this.createQRCodePlaceholder(data, config);

      Logger.debug(LogTags.QR, `QR code generated successfully`);
      return pixelMap;
    } catch (error) {
      Logger.error(LogTags.QR, 'QR code generation failed', error as Error);
      throw new Error(`QR code generation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 生成 QR 码为 Base64
   * @param data QR 码内容
   * @param options 可选配置
   * @returns Base64 编码的 QR 码图片
   */
  async generateBase64(data: string, options?: Partial<QRStyleConfig>): Promise<string | null> {
    Logger.info(LogTags.QR, `Generating QR code as Base64`);

    try {
      const pixelMap = await this.generate(data, options);
      if (!pixelMap) {
        return null;
      }

      // 将 PixelMap 转换为 Base64
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };

      const dataBlob = await imagePackerApi.packing(pixelMap, packOpts);
      imagePackerApi.release();

      // 转换为 Base64
      const base64 = this.uint8ArrayToBase64(dataBlob);

      Logger.debug(LogTags.QR, `QR code Base64 generated: ${base64.substring(0, 50)}...`);
      return `data:image/png;base64,${base64}`;
    } catch (error) {
      Logger.error(LogTags.QR, 'QR code Base64 generation failed', error as Error);
      return null;
    }
  }

  /**
   * 开始扫描 QR 码
   * @param options 扫描配置
   * @returns 扫描结果流
   */
  startScanning(options?: Partial<QRScanConfig>): QRScanEvent[] {
    Logger.info(LogTags.QR, 'Starting QR code scanning');

    if (this.isScanning) {
      Logger.warn(LogTags.QR, 'Already scanning');
      return this.eventStream;
    }

    try {
      this.scanConfig = { ...this.scanConfig, ...options };
      this.isScanning = true;

      // 清空之前的事件流
      this.eventStream = [];

      // 添加相机启动事件
      this.eventStream.push({
        type: QRScanEventType.CAMERA_STARTED
      });
      this.notifyCameraStarted();

      // 初始化扫描器
      this.initializeScanner();

      Logger.info(LogTags.QR, 'QR code scanning started');
      return this.eventStream;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to start scanning', error as Error);
      this.isScanning = false;
      this.eventStream.push({
        type: QRScanEventType.SCAN_ERROR,
        error: (error as Error).message
      });
      return this.eventStream;
    }
  }

  /**
   * 停止扫描 QR 码
   */
  stopScanning(): void {
    Logger.info(LogTags.QR, 'Stopping QR code scanning');

    if (!this.isScanning) {
      Logger.warn(LogTags.QR, 'Not scanning');
      return;
    }

    this.isScanning = false;

    // 释放扫描器资源
    this.releaseScanner();

    // 添加相机停止事件
    this.eventStream.push({
      type: QRScanEventType.CAMERA_STOPPED
    });
    this.notifyCameraStopped();

    Logger.info(LogTags.QR, 'QR code scanning stopped');
  }

  /**
   * 切换闪光灯
   * @param enable 是否启用
   */
  async toggleFlash(enable: boolean): Promise<boolean> {
    Logger.info(LogTags.QR, `Toggling flash: ${enable}`);

    if (!this.scanBarcodeInstance || !this.isScanning) {
      Logger.warn(LogTags.QR, 'Scanner not active');
      return false;
    }

    try {
      await this.scanBarcodeInstance.openFlash(enable);
      this.scanConfig.enableFlash = enable;

      Logger.info(LogTags.QR, `Flash ${enable ? 'enabled' : 'disabled'}`);
      this.notifyFlashChanged(enable);
      return true;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to toggle flash', error as Error);
      return false;
    }
  }

  /**
   * 从相册选择并扫描
   * @returns 扫描结果
   */
  async scanFromGallery(): Promise<QRScanResult | null> {
    Logger.info(LogTags.QR, 'Scanning from gallery');

    if (!this.abilityContext) {
      Logger.error(LogTags.QR, 'Ability context not set');
      return null;
    }

    try {
      // 使用 FilePicker 选择图片
      const photoSelectOptions = {
        MIMEType: scanBarcode.MIMEType.IMAGE_TYPE,
        maxSelectNumber: 1
      };

      const photoPicker = new scanBarcode.PhotoAccessHelper(this.abilityContext);
      const selectResult = await photoPicker.select(photoSelectOptions);

      if (!selectResult || selectResult.length === 0) {
        Logger.debug(LogTags.QR, 'No image selected');
        return null;
      }

      const imageUri = selectResult[0];
      return await this.scanImage(imageUri);
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to scan from gallery', error as Error);
      return null;
    }
  }

  /**
   * 扫描指定图片
   * @param imageUri 图片 URI
   * @returns 扫描结果
   */
  async scanImage(imageUri: string): Promise<QRScanResult | null> {
    Logger.debug(LogTags.QR, `Scanning image: ${imageUri}`);

    try {
      // 创建 ImageSource
      const imageSource = image.createImageSource(imageUri);

      // 配置扫描选项
      const scanOptions: scanBarcode.ScanOptions = {
        scanTypes: [scanBarcode.ScanType.SCAN_TYPE_QR_CODE],
        enableMultiMode: false,
        enableAlbum: false
      };

      // 创建扫描器
      const scanBarcodeInstance = new scanBarcode.ScanBarcode(this.abilityContext);

      // 扫描图片
      const results = await scanBarcodeInstance.scan(imageSource, scanOptions);

      if (!results || results.length === 0) {
        Logger.debug(LogTags.QR, 'No QR code found in image');
        return null;
      }

      // 获取第一个结果
      const scanResult = results[0];
      const result: QRScanResult = {
        content: scanResult.originalValue || scanResult.rawValue,
        format: this.getScanTypeName(scanResult.scanType),
        scanType: scanResult.scanType as ScanType,
        timestamp: Date.now(),
        originalValue: scanResult.originalValue,
        cornerPoints: scanResult.cornerPoints
      };

      Logger.info(LogTags.QR, `QR code found: ${result.content}`);
      return result;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to scan image', error as Error);
      return null;
    }
  }

  /**
   * 获取扫描结果流
   * @returns 扫描事件流
   */
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
    return true;
  }

  // ========== 私有方法 ==========

  /**
   * 获取默认配置
   */
  private getDefaultConfig(): QRStyleConfig {
    return {
      size: 300,
      margin: 2,
      errorCorrectionLevel: QRErrorCorrectionLevel.M,
      foregroundColor: 0xFF000000, // 黑色
      backgroundColor: 0xFFFFFFFF // 白色
    };
  }

  /**
   * 获取默认扫描配置
   */
  private getDefaultScanConfig(): QRScanConfig {
    return {
      enableFlash: false,
      enableBeep: true,
      scanInterval: 500,
      scanTypes: [ScanType.QR_CODE],
      supportGallery: true
    };
  }

  /**
   * 初始化扫描器
   */
  private initializeScanner(): void {
    if (!this.abilityContext) {
      Logger.error(LogTags.QR, 'Ability context not set');
      return;
    }

    try {
      this.scanBarcodeInstance = new scanBarcode.ScanBarcode(this.abilityContext);

      // 配置扫描选项
      const scanOptions: scanBarcode.ScanOptions = {
        scanTypes: this.scanConfig.scanTypes.filter(t => t !== ScanType.ALL),
        enableMultiMode: false,
        enableAlbum: this.scanConfig.supportGallery
      };

      // 创建自定义扫码控件
      // 注意：实际使用时需要在 UI 中创建扫码控件
      // 以下代码仅作参考

      Logger.debug(LogTags.QR, 'Scanner initialized');
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to initialize scanner', error as Error);
    }
  }

  /**
   * 释放扫描器资源
   */
  private releaseScanner(): void {
    if (this.scanBarcodeInstance) {
      try {
        if (this.scanConfig.enableFlash) {
          this.scanBarcodeInstance.closeFlash().catch(e => {
            Logger.error(LogTags.QR, 'Failed to close flash', e as Error);
          });
        }
        // 释放扫描器资源
        this.scanBarcodeInstance.release();
        this.scanBarcodeInstance = null;
        Logger.debug(LogTags.QR, 'Scanner released');
      } catch (error) {
        Logger.error(LogTags.QR, 'Failed to release scanner', error as Error);
      }
    }
  }

  /**
   * 处理扫描结果
   */
  private handleScanResult(results: Array<scanBarcode.ScanResult>): void {
    if (!results || results.length === 0) {
      return;
    }

    for (const result of results) {
      const scanResult: QRScanResult = {
        content: result.originalValue || result.rawValue,
        format: this.getScanTypeName(result.scanType),
        scanType: result.scanType as ScanType,
        timestamp: Date.now(),
        originalValue: result.originalValue,
        cornerPoints: result.cornerPoints
      };

      Logger.info(LogTags.QR, `Scan result: ${scanResult.content}`);

      // 添加到事件流
      this.eventStream.push({
        type: QRScanEventType.SCAN_SUCCESS,
        data: scanResult
      });

      // 触发回调
      this.notifyScanSuccess(scanResult);
    }
  }

  /**
   * 创建 QR 码占位图片（需要集成真实 QR 码库）
   * 注意：HarmonyOS 需要集成第三方 QR 码生成库
   */
  private async createQRCodePlaceholder(data: string, config: QRStyleConfig): Promise<image.PixelMap | null> {
    try {
      // 创建一个简单的占位图片
      const size = config.size;
      const imageInfo: image.ImageInfo = {
        size: { width: size, height: size },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };

      const pixelMap = await image.createPixelMap(imageInfo, {
        editable: true,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        size: { width: size, height: size }
      });

      // 填充背景色
      const bufferData = new Uint8Array(pixelMap.getPixelBytesNumber());
      const bgColor = config.backgroundColor;
      const fgColor = config.foregroundColor;

      for (let i = 0; i < bufferData.length; i += 4) {
        bufferData[i] = (bgColor >> 16) & 0xFF;     // R
        bufferData[i + 1] = (bgColor >> 8) & 0xFF;  // G
        bufferData[i + 2] = bgColor & 0xFF;         // B
        bufferData[i + 3] = (bgColor >> 24) & 0xFF; // A
      }

      // 写入像素数据
      await pixelMap.writeBufferToPixels(bufferData);

      Logger.debug(LogTags.QR, 'QR code placeholder created');
      return pixelMap;
    } catch (error) {
      Logger.error(LogTags.QR, 'Failed to create QR code placeholder', error as Error);
      return null;
    }
  }

  /**
   * 获取扫描类型名称
   */
  private getScanTypeName(scanType: number): string {
    switch (scanType) {
      case scanBarcode.ScanType.SCAN_TYPE_QR_CODE:
        return 'QR_CODE';
      case scanBarcode.ScanType.SCAN_TYPE_BARCODE:
        return 'BARCODE';
      case scanBarcode.ScanType.SCAN_TYPE_CODE_128:
        return 'CODE_128';
      case scanBarcode.ScanType.SCAN_TYPE_CODE_39:
        return 'CODE_39';
      case scanBarcode.ScanType.SCAN_TYPE_CODE_93:
        return 'CODE_93';
      case scanBarcode.ScanType.SCAN_TYPE_CODABAR:
        return 'CODABAR';
      case scanBarcode.ScanType.SCAN_TYPE_DATA_MATRIX:
        return 'DATA_MATRIX';
      case scanBarcode.ScanType.SCAN_TYPE_EAN_13:
        return 'EAN_13';
      case scanBarcode.ScanType.SCAN_TYPE_EAN_8:
        return 'EAN_8';
      case scanBarcode.ScanType.SCAN_TYPE_ITF_14:
        return 'ITF_14';
      case scanBarcode.ScanType.SCAN_TYPE_PDF_417:
        return 'PDF_417';
      case scanBarcode.ScanType.SCAN_TYPE_UPC_A:
        return 'UPC_A';
      case scanBarcode.ScanType.SCAN_TYPE_UPC_E:
        return 'UPC_E';
      default:
        return 'UNKNOWN';
    }
  }

  /**
   * Uint8Array 转 Base64
   */
  private uint8ArrayToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < uint8Array.length; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * 通知扫描成功
   */
  private notifyScanSuccess(result: QRScanResult): void {
    if (this.eventCallbacks.onScanSuccess) {
      this.eventCallbacks.onScanSuccess(result);
    }
  }

  /**
   * 通知扫描错误
   */
  private notifyScanError(error: string): void {
    if (this.eventCallbacks.onScanError) {
      this.eventCallbacks.onScanError(error);
    }
  }

  /**
   * 通知相机已启动
   */
  private notifyCameraStarted(): void {
    if (this.eventCallbacks.onCameraStarted) {
      this.eventCallbacks.onCameraStarted();
    }
  }

  /**
   * 通知相机已停止
   */
  private notifyCameraStopped(): void {
    if (this.eventCallbacks.onCameraStopped) {
      this.eventCallbacks.onCameraStopped();
    }
  }

  /**
   * 通知闪光灯状态变化
   */
  private notifyFlashChanged(enabled: boolean): void {
    if (this.eventCallbacks.onFlashChanged) {
      this.eventCallbacks.onFlashChanged(enabled);
    }
  }

  /**
   * 清理资源
   */
  dispose(): void {
    Logger.debug(LogTags.QR, 'Disposing QR Plugin');
    this.stopScanning();
    this.eventStream = [];
  }
}

/**
 * QR 管理器（单例）
 */
class QRManager {
  private static instance: QRPlugin;

  static getInstance(): QRPlugin {
    if (!QRManager.instance) {
      QRManager.instance = new QRPlugin();
    }
    return QRManager.instance;
  }
}

/**
 * 导出单例实例
 */
export const qrPlugin = QRManager.getInstance();
