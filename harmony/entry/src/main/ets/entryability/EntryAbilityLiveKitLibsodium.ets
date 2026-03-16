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

import { EntryAbilityBase } from './EntryAbilityBase';

export class EntryAbilityLiveKitLibsodium extends EntryAbilityBase {
  protected setupLiveKitChannel(): void {
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

  protected setupLibsodiumChannel(): void {
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
}
