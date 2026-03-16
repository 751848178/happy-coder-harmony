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

export class HappyQRCodePluginBase {
  protected methodChannel: MethodChannel | null = null;
  protected eventChannel: EventChannel | null = null;
  protected eventSink: EventSink | null = null;
  protected abilityContext: common.UIAbilityContext | null = null;
  protected readonly base64Helper = new util.Base64Helper();
  protected isScanning = false;
  protected flashEnabled = false;
  protected asArgsMap(
    value: Object | null,
  ): Map<string, Object> | null {
    if (value == null || !(value instanceof Map)) {
      return null;
    }
    return value as Map<string, Object>;
  }

  protected readString(
    args: Map<string, Object> | null,
    key: string,
  ): string | null {
    if (args == null || !args.has(key)) {
      return null;
    }
    const value = args.get(key);
    return typeof value === 'string' ? value.trim() : null;
  }

  protected readBool(
    args: Map<string, Object> | null,
    key: string,
  ): boolean | null {
    if (args == null || !args.has(key)) {
      return null;
    }
    const value = args.get(key);
    return typeof value === 'boolean' ? value : null;
  }

  protected readNumber(
    args: Map<string, Object> | null,
    key: string,
  ): number | null {
    if (args == null || !args.has(key)) {
      return null;
    }
    const value = args.get(key);
    return typeof value === 'number' ? value : null;
  }

  protected readScanTypes(args: Map<string, Object> | null): Array<scanCore.ScanType> {
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

  protected getScanTypeName(type: scanCore.ScanType): string {
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
