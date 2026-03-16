import { Logger, LogTags } from '../utils/Logger';
import scanBarcode from '@ohos.multimedia.scanBarcode';
import image from '@ohos.multimedia.image';
import { QREventCallbacks, QRScanResult, QRStyleConfig } from './QRPluginModels';
import { QRPluginBase } from './QRPluginBase';

export class QRPluginSupport extends QRPluginBase {
  protected handleScanResult(results: Array<scanBarcode.ScanResult>): void {
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
  protected async createQRCodePlaceholder(data: string, config: QRStyleConfig): Promise<image.PixelMap | null> {
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
  protected getScanTypeName(scanType: number): string {
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
  protected uint8ArrayToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < uint8Array.length; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * 通知扫描成功
}
