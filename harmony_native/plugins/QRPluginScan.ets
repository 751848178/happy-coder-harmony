import image from '@ohos.multimedia.image';
import detectBarcode from '@hms.core.scan.detectBarcode';
import scanCore from '@hms.core.scan.scanCore';
import generateBarcode from '@hms.core.scan.generateBarcode';
import { Logger, LogTags } from '../utils/Logger';
import { Conversion } from '../utils/Conversion';
import { QRScanConfig, QRStyleConfig } from './QRPluginModels';
import { QRPluginSupport } from './QRPluginSupport';

export class QRPluginScan extends QRPluginSupport {
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
}
