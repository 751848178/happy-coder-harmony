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

import { EntryAbilityDeviceChannel } from './EntryAbilityDeviceChannel';

export class EntryAbilityCallbacks extends EntryAbilityDeviceChannel {
  protected setupPluginCallbacks(): void {
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
}
