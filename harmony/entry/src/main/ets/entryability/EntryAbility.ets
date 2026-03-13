// Happy Coder HarmonyOS Entry Point
//
// Flutter 鸿蒙混合应用的入口能力
//
// 主要功能：
// 1. 启动 Flutter Engine
// 2. 提供原生方法给 Flutter (MethodChannel)
// 3. 处理 Flutter 无法实现的原生功能

import UIAbility from '@ohos.ability.ability';
import window from '@ohos.window';
import { Logger, LogTags } from '../utils/Logger';
import common from '@ohos.app.ability.common';

// 导入插件
import { liveKitPlugin, LiveKitConnectionState } from '../plugins/LiveKitPlugin';
import { libsodiumPlugin } from '../plugins/LibsodiumPlugin';
import { pushPlugin } from '../plugins/PushPlugin';
import { qrPlugin } from '../plugins/QRPlugin';
import { filePlugin } from '../plugins/FilePlugin';
import { devicePlugin } from '../plugins/DevicePlugin';

/**
 * Flutter Bridge 插件引用
 * 注意：以下代码假设使用 Flutter HarmonyOS Bridge 框架
 * 实际集成时需要根据具体的 Bridge 框架调整
 */
type MethodChannel = any;
type EventChannel = any;

/**
 * 应用入口
 */
export default class EntryAbility extends UIAbility {
  private abilityContext: common.Context | null = null;

  // MethodChannel 实例
  private livekitChannel: MethodChannel | null = null;
  private libsodiumChannel: MethodChannel | null = null;
  private pushChannel: MethodChannel | null = null;
  private qrChannel: MethodChannel | null = null;
  private fileChannel: MethodChannel | null = null;
  private deviceChannel: MethodChannel | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);

    this.abilityContext = this.context;

    Logger.info(LogTags.DEFAULT, 'Happy Coder App started');
    Logger.info(LogTags.DEFAULT, `Launch reason: ${launchParam.launchReason}`);

    // 初始化插件（设置 Context）
    this.initializePlugins();

    // 设置插件事件回调
    this.setupPluginCallbacks();

    // 注册原生方法通道
    this.setupMethodChannels();

    Logger.info(LogTags.DEFAULT, 'All channels initialized');
  }

  onDestroy(): void {
    Logger.info(LogTags.DEFAULT, 'Happy Coder App destroying');

    // 清理插件
    this.disposePlugins();

    // 清理 MethodChannel
    this.livekitChannel = null;
    this.libsodiumChannel = null;
    this.pushChannel = null;
    this.qrChannel = null;
    this.fileChannel = null;
    this.deviceChannel = null;

    super.onDestroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(LogTags.DEFAULT, 'Window stage created');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error(LogTags.DEFAULT, `Failed to load page: ${err.message}`);
        return;
      }
      Logger.info(LogTags.DEFAULT, 'Page loaded successfully');
    });
  }

  onWindowStageDestroy(): void {
    Logger.info(LogTags.DEFAULT, 'Window stage destroyed');
  }

  onForeground(): void {
    Logger.info(LogTags.DEFAULT, 'App moved to foreground');
  }

  onBackground(): void {
    Logger.info(LogTags.DEFAULT, 'App moved to background');
  }

  // ========== 插件初始化 ==========

  /**
   * 初始化插件
   */
  private initializePlugins(): void {
    if (!this.abilityContext) {
      Logger.error(LogTags.DEFAULT, 'Ability context not available');
      return;
    }

    Logger.info(LogTags.DEFAULT, 'Initializing plugins');

    // 设置 Context
    liveKitPlugin.setContext(this.abilityContext);
    qrPlugin.setContext(this.abilityContext);
    pushPlugin.setContext(this.abilityContext);
    filePlugin.setContext(this.abilityContext);
    devicePlugin.setContext(this.abilityContext);

    // 配置插件
    this.configurePlugins();

    Logger.info(LogTags.DEFAULT, 'Plugins initialized');
  }

  /**
   * 配置插件
   */
  private configurePlugins(): void {
    // LiveKit 音频配置
    liveKitPlugin.setAudioConfig({
      sampleRate: 16000,
      channelCount: 1,
      bitsPerSample: 16,
      frameSize: 960,
      bufferSize: 4096
    });

    Logger.debug(LogTags.DEFAULT, 'Plugins configured');
  }

  /**
   * 清理插件
   */
  private disposePlugins(): void {
    Logger.info(LogTags.DEFAULT, 'Disposing plugins');

    liveKitPlugin.dispose();
    pushPlugin.dispose();
    qrPlugin.dispose();
    devicePlugin.dispose();
    libsodiumPlugin.dispose();

    Logger.info(LogTags.DEFAULT, 'Plugins disposed');
  }

  // ========== MethodChannel 设置 ==========

  /**
   * 设置原生方法通道
   */
  private setupMethodChannels(): void {
    Logger.info(LogTags.DEFAULT, 'Setting up method channels');

    // 注意：以下代码假设使用 Flutter HarmonyOS Bridge
    // 实际实现需要根据具体的 Bridge 框架调整
    // 例如：MethodChannel 可能需要通过 Flutter Bridge API 创建

    // ========== LiveKit 实时语音通道 ==========
    this.setupLiveKitChannel();

    // ========== Libsodium 加密通道 ==========
    this.setupLibsodiumChannel();

    // ========== 推送通知通道 ==========
    this.setupPushChannel();

    // ========== QR 码通道 ==========
    this.setupQRChannel();

    // ========== 文件操作通道 ==========
    this.setupFileChannel();

    // ========== 设备信息通道 ==========
    this.setupDeviceChannel();
  }

  // ========== LiveKit 通道 ==========

  private setupLiveKitChannel(): void {
    // 创建 MethodChannel（示例，实际需要根据 Bridge 框架调整）
    // this.livekitChannel = new MethodChannel('happy.livekit', flutterBridge);

    // 设置方法调用处理器
    const handlers: Record<string, Function> = {
      'connectSession': (args: Record<string, Object>) => {
        return liveKitPlugin.connectSession(args['token'] as string);
      },
      'disconnect': () => {
        return liveKitPlugin.disconnect();
      },
      'sendAudio': (args: Record<string, Object>) => {
        const data = args['data'] as ArrayBuffer;
        return liveKitPlugin.sendAudio(data);
      },
      'toggleMute': () => {
        return liveKitPlugin.toggleMute();
      },
      'getMuted': () => {
        return liveKitPlugin.getMuted();
      },
      'getConnectionState': () => {
        return liveKitPlugin.getConnectionState();
      },
      'startRecording': () => {
        return liveKitPlugin.startRecording();
      },
      'stopRecording': () => {
        return liveKitPlugin.stopRecording();
      },
      'startPlayback': () => {
        return liveKitPlugin.startPlayback();
      },
      'stopPlayback': () => {
        return liveKitPlugin.stopPlayback();
      },
      'ping': () => {
        return liveKitPlugin.ping();
      }
    };

    // 注册处理器到 Bridge
    // this.livekitChannel.setMethodCallHandler(handlers);

    Logger.info(LogTags.LIVEKIT, 'LiveKit channel handlers registered');
  }

  // ========== Libsodium 通道 ==========

  private setupLibsodiumChannel(): void {
    // this.libsodiumChannel = new MethodChannel('happy.libsodium', flutterBridge);

    const handlers: Record<string, Function> = {
      'generateKey': () => {
        return libsodiumPlugin.generateKey();
      },
      'generateKeyPair': () => {
        return libsodiumPlugin.generateKeyPair();
      },
      'generateRandom': (args: Record<string, Object>) => {
        const size = (args['size'] as number) || 32;
        return libsodiumPlugin.generateRandom(size);
      },
      'encrypt': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        const key = args['key'] as string;
        return libsodiumPlugin.encrypt(data, key);
      },
      'decrypt': (args: Record<string, Object>) => {
        const encrypted = args['encrypted'] as string;
        const key = args['key'] as string;
        return libsodiumPlugin.decrypt(encrypted, key);
      },
      'encryptForPublicKey': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        const publicKey = args['publicKey'] as string;
        return libsodiumPlugin.encryptForPublicKey(data, publicKey);
      },
      'decryptFromPublicKey': (args: Record<string, Object>) => {
        const encrypted = args['encrypted'] as string;
        const secretKey = args['secretKey'] as string;
        return libsodiumPlugin.decryptFromPublicKey(encrypted, secretKey);
      },
      'hash': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        return libsodiumPlugin.hash(data);
      },
      'hash512': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        return libsodiumPlugin.hash512(data);
      },
      'hmac': (args: Record<string, Object>) => {
        const data = args['data'] as string;
        const key = args['key'] as string;
        return libsodiumPlugin.hmac(data, key);
      },
      'ping': () => {
        return libsodiumPlugin.ping();
      }
    };

    // this.libsodiumChannel.setMethodCallHandler(handlers);

    Logger.info(LogTags.LIBSODIUM, 'Libsodium channel handlers registered');
  }

  // ========== Push 通道 ==========

  private setupPushChannel(): void {
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

  private setupQRChannel(): void {
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

  private setupFileChannel(): void {
    // this.fileChannel = new MethodChannel('happy.file', flutterBridge);

    const handlers: Record<string, Function> = {
      'selectFiles': (args: Record<string, Object>) => {
        const mimeTypes = (args['mimeTypes'] as string[]) || [];
        const multiple = (args['multiple'] as boolean) || false;
        return filePlugin.selectFiles(mimeTypes, multiple);
      },
      'selectFile': (args: Record<string, Object>) => {
        const mimeType = args['mimeType'] as string;
        return filePlugin.selectFile(mimeType);
      },
      'selectImage': (args: Record<string, Object>) => {
        const options = args['options'] as any;
        return filePlugin.selectImage(options);
      },
      'selectImages': (args: Record<string, Object>) => {
        const maxCount = (args['maxCount'] as number) || 9;
        return filePlugin.selectImages(maxCount);
      },
      'selectVideos': (args: Record<string, Object>) => {
        const maxCount = (args['maxCount'] as number) || 1;
        return filePlugin.selectVideos(maxCount);
      },
      'saveFile': (args: Record<string, Object>) => {
        const content = args['content'] as string;
        const options = args['options'] as any;
        return filePlugin.saveFile(content, options);
      },
      'getInfo': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.getFileInfo(uri);
      },
      'getMultipleFileInfo': (args: Record<string, Object>) => {
        const uris = args['uris'] as string[];
        return filePlugin.getMultipleFileInfo(uris);
      },
      'getDirectoryInfo': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.getDirectoryInfo(uri);
      },
      'readFile': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.readFile(uri);
      },
      'readFileBinary': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const offset = args['offset'] as number;
        const length = args['length'] as number;
        return filePlugin.readFileBinary(uri, offset, length);
      },
      'writeFile': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const content = args['content'] as string;
        return filePlugin.writeFile(uri, content);
      },
      'writeFileBinary': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const data = args['data'] as ArrayBuffer;
        return filePlugin.writeFileBinary(uri, data);
      },
      'copyFile': (args: Record<string, Object>) => {
        const sourceUri = args['sourceUri'] as string;
        const targetUri = args['targetUri'] as string;
        return filePlugin.copyFile(sourceUri, targetUri);
      },
      'moveFile': (args: Record<string, Object>) => {
        const sourceUri = args['sourceUri'] as string;
        const targetUri = args['targetUri'] as string;
        return filePlugin.moveFile(sourceUri, targetUri);
      },
      'deleteFile': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.deleteFile(uri);
      },
      'fileExists': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.fileExists(uri);
      },
      'createDirectory': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const recursive = (args['recursive'] as boolean) || true;
        return filePlugin.createDirectory(uri, recursive);
      },
      'ping': () => {
        return filePlugin.ping();
      }
    };

    // this.fileChannel.setMethodCallHandler(handlers);

    Logger.info(LogTags.FILE, 'File channel handlers registered');
  }

  // ========== Device 通道 ==========

  private setupDeviceChannel(): void {
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
  private setupPluginCallbacks(): void {
    Logger.info(LogTags.DEFAULT, 'Setting up plugin callbacks');

    // LiveKit 事件
    liveKitPlugin.setEventCallbacks({
      onConnectionStateChanged: (state: LiveKitConnectionState) => {
        Logger.info(LogTags.LIVEKIT, `Connection state: ${state}`);
        // 通知 Flutter
        // this.sendLiveKitEvent({ type: 'connectionStateChange', state });
      },
      onAudioData: (data: Uint8Array) => {
        // 通知 Flutter 收到音频数据
        // this.sendLiveKitEvent({ type: 'audioData', data });
      },
      onError: (error: string) => {
        Logger.error(LogTags.LIVEKIT, error);
        // this.sendLiveKitEvent({ type: 'error', error });
      },
      onMuteChanged: (muted: boolean) => {
        Logger.info(LogTags.LIVEKIT, `Muted: ${muted}`);
        // this.sendLiveKitEvent({ type: 'muteChanged', muted });
      },
      onParticipantJoined: (participantId: string) => {
        Logger.info(LogTags.LIVEKIT, `Participant joined: ${participantId}`);
        // this.sendLiveKitEvent({ type: 'participantJoined', participantId });
      },
      onParticipantLeft: (participantId: string) => {
        Logger.info(LogTags.LIVEKIT, `Participant left: ${participantId}`);
        // this.sendLiveKitEvent({ type: 'participantLeft', participantId });
      }
    });

    // QR 扫描事件
    qrPlugin.setEventCallbacks({
      onScanSuccess: (result) => {
        Logger.info(LogTags.QR, `Scan success: ${result.content}`);
        // 通知 Flutter
        // this.sendQREvent({ type: 'scanSuccess', result });
      },
      onScanError: (error) => {
        Logger.error(LogTags.QR, error);
        // this.sendQREvent({ type: 'scanError', error });
      },
      onCameraStarted: () => {
        Logger.info(LogTags.QR, 'Camera started');
      },
      onCameraStopped: () => {
        Logger.info(LogTags.QR, 'Camera stopped');
      },
      onFlashChanged: (enabled: boolean) => {
        Logger.info(LogTags.QR, `Flash ${enabled ? 'enabled' : 'disabled'}`);
      }
    });

    // Push 事件
    pushPlugin.setEventCallbacks({
      onTokenRefresh: (token) => {
        Logger.info(LogTags.PUSH, `Token refreshed: ${token.substring(0, 20)}...`);
        // 通知 Flutter
        // this.sendPushEvent({ type: 'tokenRefresh', token });
      },
      onMessageReceived: (message) => {
        Logger.info(LogTags.PUSH, `Message received: ${message.title}`);
        // 通知 Flutter
        // this.sendPushEvent({ type: 'messageReceived', message });
      },
      onMessageClicked: (message) => {
        Logger.info(LogTags.PUSH, `Message clicked: ${message.title}`);
      },
      onError: (error) => {
        Logger.error(LogTags.PUSH, error);
      },
      onConnected: () => {
        Logger.info(LogTags.PUSH, 'Push service connected');
      },
      onDisconnected: () => {
        Logger.info(LogTags.PUSH, 'Push service disconnected');
      }
    });

    Logger.debug(LogTags.DEFAULT, 'Plugin callbacks configured');
  }

  // ========== Flutter 事件发送 ==========

  /**
   * 发送 LiveKit 事件到 Flutter
   */
  private sendLiveKitEvent(event: any): void {
    // 实际实现需要通过 MethodChannel 发送事件
    Logger.debug(LogTags.LIVEKIT, `Sending event to Flutter: ${JSON.stringify(event)}`);
  }

  /**
   * 发送 QR 事件到 Flutter
   */
  private sendQREvent(event: any): void {
    // 实际实现需要通过 MethodChannel 发送事件
    Logger.debug(LogTags.QR, `Sending event to Flutter: ${JSON.stringify(event)}`);
  }

  /**
   * 发送 Push 事件到 Flutter
   */
  private sendPushEvent(event: any): void {
    // 实际实现需要通过 MethodChannel 发送事件
    Logger.debug(LogTags.PUSH, `Sending event to Flutter: ${JSON.stringify(event)}`);
  }
}
