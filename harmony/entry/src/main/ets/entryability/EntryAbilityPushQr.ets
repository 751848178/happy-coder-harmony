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

import { EntryAbilityLiveKitLibsodium } from './EntryAbilityLiveKitLibsodium';

export class EntryAbilityPushQr extends EntryAbilityLiveKitLibsodium {
  protected setupPushChannel(): void {
    // this.pushChannel = new MethodChannel('happy.push', flutterBridge);

    const handlers: Record<string, Function> = {
      'initialize': (args: Record<string, Object>) => {
        const appId = args['appId'] as string;
        return pushPlugin.initialize(appId);
      },
      'requestPermissions': () => {
        return pushPlugin.requestPermissions();
      },
      'getInitialMessage': () => {
        return pushPlugin.getInitialMessage();
      },
      'getToken': () => {
        return pushPlugin.getToken();
      },
      'refreshToken': () => {
        return pushPlugin.refreshToken();
      },
      'getConnectionStatus': () => {
        return pushPlugin.getConnectionStatus();
      },
      'showLocalNotification': (args: Record<string, Object>) => {
        const title = args['title'] as string;
        const content = args['body'] as string;
        const extras = args['extras'] as Record<string, any>;
        return pushPlugin.showLocalNotification(title, content, extras);
      },
      'clearAllNotifications': () => {
        return pushPlugin.clearAllNotifications();
      },
      'ping': () => {
        return pushPlugin.ping();
      }
    };

    // this.pushChannel.setMethodCallHandler(handlers);

    // 创建 EventChannel 用于推送事件
    // const pushEventChannel = new EventChannel('happy.push/events', flutterBridge);
    // pushEventChannel.setStreamHandler({
    //   onListen: () => pushPlugin.getEventStream(),
    //   onCancel: () => {}
    // });

    Logger.info(LogTags.PUSH, 'Push channel handlers registered');
  }

  // ========== QR 通道 ==========

  protected setupQRChannel(): void {
    // this.qrChannel = new MethodChannel('happy.qrcode', flutterBridge);

    const handlers: Record<string, Function> = {
      'generate': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        const size = (args['size'] as number) || 200;
        return qrPlugin.generate(data, { size });
      },
      'generateBase64': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        const size = (args['size'] as number) || 200;
        return qrPlugin.generateBase64(data, { size });
      },
      'scanQRCode': (args: Record<string, Object>) => {
        const config = args['config'] as any;
        return qrPlugin.startScanning(config);
      },
      'stopScan': () => {
        qrPlugin.stopScanning();
      },
      'scanFromGallery': () => {
        return qrPlugin.scanFromGallery();
      },
      'scanImage': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return qrPlugin.scanImage(uri);
      },
      'checkCameraPermission': () => {
        return qrPlugin.checkCameraPermission();
      },
      'requestCameraPermission': () => {
        return qrPlugin.requestCameraPermission();
      },
      'toggleFlash': (args: Record<string, Object>) => {
        const enable = (args['enable'] as boolean) ?? true;
        return qrPlugin.toggleFlash(enable);
      },
      'isScanningActive': () => {
        return qrPlugin.isScanningActive();
      },
      'ping': () => {
        return qrPlugin.ping();
      }
    };

    // this.qrChannel.setMethodCallHandler(handlers);

    // 创建 EventChannel 用于扫描事件
    // const qrEventChannel = new EventChannel('happy.qrcode/events', flutterBridge);
    // qrEventChannel.setStreamHandler({
    //   onListen: () => qrPlugin.getEventStream(),
    //   onCancel: () => {}
    // });

    Logger.info(LogTags.QR, 'QR channel handlers registered');
  }

  // ========== File 通道 ==========
}
