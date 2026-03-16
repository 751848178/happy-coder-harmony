import UIAbility from '@ohos.ability.ability';
import window from '@ohos.window';
import { Logger, LogTags } from '../utils/Logger';
import common from '@ohos.app.ability.common';
import { liveKitPlugin, LiveKitConnectionState } from '../plugins/LiveKitPlugin';
import { libsodiumPlugin } from '../plugins/LibsodiumPlugin';
import { pushPlugin } from '../plugins/PushPlugin';
import { qrPlugin } from '../plugins/QRPlugin';
import { filePlugin } from '../plugins/FilePlugin';
import { devicePlugin } from '../plugins/DevicePlugin';

type MethodChannel = any;
type EventChannel = any;

import { EntryAbilityFileChannel } from './EntryAbilityFileChannel';

export class EntryAbilityDeviceChannel extends EntryAbilityFileChannel {
  protected setupDeviceChannel(): void {
    // this.deviceChannel = new MethodChannel('happy.device', flutterBridge);

    const handlers: Record<string, Function> = {
      'getInfo': () => {
        return devicePlugin.getDeviceInfo();
      },
      'getNetworkStatus': () => {
        return devicePlugin.getNetworkStatus();
      },
      'getBatteryInfo': () => {
        return devicePlugin.getBatteryInfo();
      },
      'requestCameraPermission': () => {
        return devicePlugin.requestCameraPermission();
      },
      'requestMicrophonePermission': () => {
        return devicePlugin.requestMicrophonePermission();
      },
      'requestStoragePermission': () => {
        return devicePlugin.requestStoragePermission();
      },
      'requestLocationPermission': () => {
        return devicePlugin.requestLocationPermission();
      },
      'requestMultiplePermissions': (args: Record<string, Object>) => {
        const permissions = args['permissions'] as string[];
        return devicePlugin.requestMultiplePermissions(permissions);
      },
      'checkPermission': (args: Record<string, Object>) => {
        const permission = args['permission'] as string;
        return devicePlugin.checkPermission(permission as any);
      },
      'setClipboard': (args: Record<string, Object>) => {
        const text = args['text'] as string;
        return devicePlugin.setClipboard(text);
      },
      'getClipboard': () => {
        return devicePlugin.getClipboard();
      },
      'clearClipboard': () => {
        return devicePlugin.clearClipboard();
      },
      'openAppSettings': () => {
        return devicePlugin.openAppSettings();
      },
      'getCurrentLocation': (args: Record<string, Object>) => {
        const config = args['config'] as any;
        return devicePlugin.getCurrentLocation(config);
      },
      'enableLocationUpdates': (args: Record<string, Object>) => {
        const config = args['config'] as any;
        const callback = args['callback'] as Function;
        return devicePlugin.enableLocationUpdates(config, callback);
      },
      'disableLocationUpdates': (args: Record<string, Object>) => {
        const callbackId = args['callbackId'] as number;
        return devicePlugin.disableLocationUpdates(callbackId);
      },
      'ping': () => {
        return devicePlugin.ping();
      }
    };

    // this.deviceChannel.setMethodCallHandler(handlers);

    Logger.info(LogTags.DEVICE, 'Device channel handlers registered');
  }

  // ========== 插件事件回调 ==========

  /**
   * 设置插件事件回调
   */
}
