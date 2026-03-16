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

import { METHOD_CHANNEL, EVENT_CHANNEL } from './HappyQRCodePluginModels';
import { HappyQRCodePluginMethodHandlers } from './HappyQRCodePluginMethodHandlers';

export default class HappyQRCodePlugin extends HappyQRCodePluginMethodHandlers implements
  FlutterPlugin,
  AbilityAware,
  MethodCallHandler,
  StreamHandler {
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
}
