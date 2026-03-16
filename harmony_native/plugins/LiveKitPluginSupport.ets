import { Logger, LogTags } from '../utils/Logger';
import { LiveKitConnectionState } from './LiveKitPluginModels';
import { LiveKitPluginTransport } from './LiveKitPluginTransport';

export class LiveKitPluginSupport extends LiveKitPluginTransport {
  protected handleAudioData(data: any): void {
    try {
      if (data.audio) {
        const audioData = this.base64ToUint8Array(data.audio);
        Logger.debug(LogTags.LIVEKIT, `Received ${audioData.length} bytes of audio`);

        // 播放音频数据
        this.playAudioData(audioData);

        // 触发回调
        if (this.eventCallbacks.onAudioData) {
          this.eventCallbacks.onAudioData(audioData);
        }
      }
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to handle audio data', error as Error);
    }
  }

  /**
   * 播放音频数据
   */
  protected async playAudioData(data: Uint8Array): Promise<void> {
    // 需要集成 @ohos.multimedia.media 播放音频
    // 以下是框架代码
  }

  /**
   * 处理轨道发布
   */
  protected handleTrackPublished(data: any): void {
    Logger.info(LogTags.LIVEKIT, `Track published: ${JSON.stringify(data)}`);

    if (data.participantId && this.eventCallbacks.onParticipantJoined) {
      this.eventCallbacks.onParticipantJoined(data.participantId);
    }
  }

  /**
   * 处理轨道订阅
   */
  protected handleTrackSubscribed(data: any): void {
    Logger.info(LogTags.LIVEKIT, `Track subscribed: ${JSON.stringify(data)}`);
  }

  /**
   * 处理远程静音
   */
  protected handleRemoteMute(muted: boolean): void {
    Logger.info(LogTags.LIVEKIT, `Remote muted: ${muted}`);

    if (this.eventCallbacks.onMuteChanged) {
      this.eventCallbacks.onMuteChanged(muted);
    }
  }

  /**
   * 通知连接状态变化
   */
  protected notifyConnectionStateChanged(state: LiveKitConnectionState): void {
    if (this.eventCallbacks.onConnectionStateChanged) {
      this.eventCallbacks.onConnectionStateChanged(state);
    }
  }

  /**
   * 通知错误
   */
  protected notifyError(error: string): void {
    if (this.eventCallbacks.onError) {
      this.eventCallbacks.onError(error);
    }
  }

  /**
   * 通知静音状态变化
   */
  protected notifyMuteChanged(muted: boolean): void {
    if (this.eventCallbacks.onMuteChanged) {
      this.eventCallbacks.onMuteChanged(muted);
    }
  }

  /**
   * Uint8Array 转 Base64
   */
  protected uint8ArrayToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < uint8Array.length; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * Base64 转 Uint8Array
   */
  protected base64ToUint8Array(base64: string): Uint8Array {
    const binary = atob(base64);
    const length = binary.length;
    const buffer = new ArrayBuffer(length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < length; i++) {
      uint8Array[i] = binary.charCodeAt(i);
    }
    return uint8Array;
  }

  /**
   * 清理资源
   */
}
