import scanBarcode from '@hms.core.scan.scanBarcode';
import scanCore from '@hms.core.scan.scanCore';
import generateBarcode from '@hms.core.scan.generateBarcode';
import { QRScanEvent, QRScanEventType, QRScanResult, QRErrorCorrectionLevel } from './QRPluginModels';
import { QRPluginBase } from './QRPluginBase';

export class QRPluginSupport extends QRPluginBase {
  protected mapScanResult(result: scanBarcode.ScanResult): QRScanResult {
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

  protected emitEvent(event: QRScanEvent): void {
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

  protected getScanTypeName(scanType: number): string {
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
}
