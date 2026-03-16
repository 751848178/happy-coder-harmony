import { Logger, LogTags } from '../utils/Logger';
import { WSMessage, WSMessageType } from './LiveKitPluginModels';
import { LiveKitPluginSocket } from './LiveKitPluginSocket';

export class LiveKitPluginTransport extends LiveKitPluginSocket {
  protected async sendMessage(message: WSMessage): Promise<void> {
    if (!this.ws || this.connectionState !== LiveKitConnectionState.CONNECTED) {
      Logger.warn(LogTags.LIVEKIT, 'Cannot send message: not connected');
      return;
    }

    try {
      const messageStr = JSON.stringify(message);
      this.ws.send(messageStr);
      Logger.debug(LogTags.LIVEKIT, `Sent message: ${message.type}`);
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to send message', error as Error);
    }
  }

  /**
   * 发送加入消息
   */
  protected async sendJoinMessage(): Promise<void> {
    if (!this.connectionInfo) {
      return;
    }

    await this.sendMessage({
      type: WSMessageType.JOIN,
      data: {
        room: this.connectionInfo.room,
        identity: this.connectionInfo.identity,
        token: this.currentToken,
        audioConfig: this.audioConfig
      }
    });
  }

  /**
   * 尝试重连
   */
  protected async attemptReconnect(): Promise<void> {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      Logger.error(LogTags.LIVEKIT, 'Max reconnect attempts reached');
      this.connectionState = LiveKitConnectionState.FAILED;
      this.notifyConnectionStateChanged(LiveKitConnectionState.FAILED);
      return;
    }

    this.reconnectAttempts++;
    this.connectionState = LiveKitConnectionState.RECONNECTING;
    this.notifyConnectionStateChanged(LiveKitConnectionState.RECONNECTING);

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    Logger.info(LogTags.LIVEKIT, `Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    setTimeout(async () => {
      try {
        await this.disconnect();
        const success = await this.connectSession(this.currentToken);
        if (!success) {
          this.attemptReconnect();
        }
      } catch (error) {
        Logger.error(LogTags.LIVEKIT, 'Reconnect failed', error as Error);
        this.attemptReconnect();
      }
    }, delay);
  }

  /**
   * 初始化音频处理
   */
  protected async initializeAudio(): Promise<void> {
    Logger.debug(LogTags.LIVEKIT, 'Initializing audio processing');

    // 需要集成 @ohos.multimedia.media
    // 以下是框架代码

    Logger.debug(LogTags.LIVEKIT, `Audio config: ${JSON.stringify(this.audioConfig)}`);
  }

  /**
   * 停止音频处理
   */
  protected stopAudio(): void {
    Logger.debug(LogTags.LIVEKIT, 'Stopping audio processing');

    this.stopRecording();
    this.stopPlayback();
  }

  /**
   * 处理收到的音频数据
}
