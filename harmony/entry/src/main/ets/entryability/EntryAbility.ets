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

import { EntryAbilityCallbacks } from './EntryAbilityCallbacks';

export default class EntryAbility extends EntryAbilityCallbacks {
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

  protected setupMethodChannels(): void {
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
}
