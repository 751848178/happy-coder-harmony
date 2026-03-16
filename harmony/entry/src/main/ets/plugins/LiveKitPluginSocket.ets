import { Logger, LogTags } from '../utils/Logger';
import { webSocket } from '@kit.NetworkKit';
import { LiveKitConnectionInfo, LiveKitConnectionState, WSMessage, WSMessageType } from './LiveKitPluginModels';
import { LiveKitPluginBase } from './LiveKitPluginBase';

export class LiveKitPluginSocket extends LiveKitPluginBase {
  protected parseToken(token: string): LiveKitConnectionInfo {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid token format');
    }

    try {
      const payload = JSON.parse(atob(parts[1]));

      // LiveKit token 通常包含以下字段
      return {
        token: token,
        url: payload.vid || payload.iss || '',
        room: payload.room || payload.video?.room || 'default',
        identity: payload.sub || payload.identity || 'unknown',
        serverUrl: payload.iss || ''
      };
    } catch (e) {
      throw new Error('Failed to parse token');
    }
  }

  /**
   * 建立 WebSocket 连接
   */
  protected async establishWebSocketConnection(info: LiveKitConnectionInfo): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        // 构建 WebSocket URL
        const wsProtocol = info.serverUrl.startsWith('https') ? 'wss' : 'ws';
        const wsHost = info.serverUrl.replace(/^https?:\/\//, '');
        this.wsUrl = `${wsProtocol}://${wsHost}`;

        Logger.debug(LogTags.LIVEKIT, `Connecting to WebSocket: ${this.wsUrl}`);

        // 创建 WebSocket
        this.ws = webSocket.createWebSocket();

        // 设置事件监听
        this.ws.on('open', () => {
          Logger.info(LogTags.LIVEKIT, 'WebSocket connected');
          resolve();
        });

        this.ws.on('message', (data: webSocket.WebSocketMessage) => {
          this.handleWSMessage(data);
        });

        this.ws.on('error', (error: ErrorEvent) => {
          Logger.error(LogTags.LIVEKIT, `WebSocket error: ${error.message}`);
          this.notifyError(`WebSocket error: ${error.message}`);
          reject(new Error(`WebSocket error: ${error.message}`));
        });

        this.ws.on('close', (code: number, reason: string) => {
          Logger.info(LogTags.LIVEKIT, `WebSocket closed: ${code} - ${reason}`);

          if (this.connectionState === LiveKitConnectionState.CONNECTED) {
            // 意外断开，尝试重连
            this.attemptReconnect();
          }
        });

        // 连接
        this.ws.connect(this.wsUrl, (err: BusinessError) => {
          if (err) {
            Logger.error(LogTags.LIVEKIT, `WebSocket connection failed: ${err.message}`);
            reject(new Error(`WebSocket connection failed: ${err.message}`));
          }
        });

      } catch (error) {
        Logger.error(LogTags.LIVEKIT, 'Failed to establish WebSocket connection', error as Error);
        reject(error);
      }
    });
  }

  /**
   * 关闭 WebSocket 连接
   */
  protected closeWebSocket(): void {
    if (this.ws) {
      try {
        this.ws.close(1000, 'Normal closure');
        this.ws = null;
        Logger.debug(LogTags.LIVEKIT, 'WebSocket closed');
      } catch (error) {
        Logger.error(LogTags.LIVEKIT, 'Failed to close WebSocket', error as Error);
      }
    }
  }

  /**
   * 处理 WebSocket 消息
   */
  protected handleWSMessage(message: webSocket.WebSocketMessage): void {
    try {
      let dataStr = '';
      if (typeof message.data === 'string') {
        dataStr = message.data;
      } else if (message.data instanceof ArrayBuffer) {
        dataStr = new TextDecoder().decode(message.data);
      }

      const msg: WSMessage = JSON.parse(dataStr);
      Logger.debug(LogTags.LIVEKIT, `Received message: ${msg.type}`);

      switch (msg.type) {
        case WSMessageType.AUDIO_DATA:
          this.handleAudioData(msg.data);
          break;
        case WSMessageType.TRACK_PUBLISHED:
          this.handleTrackPublished(msg.data);
          break;
        case WSMessageType.TRACK_SUBSCRIBED:
          this.handleTrackSubscribed(msg.data);
          break;
        case WSMessageType.MUTE:
        case WSMessageType.UNMUTE:
          this.handleRemoteMute(msg.type === WSMessageType.MUTE);
          break;
        case WSMessageType.ERROR:
          this.notifyError(msg.error || 'Unknown error');
          break;
        default:
          Logger.debug(LogTags.LIVEKIT, `Unhandled message type: ${msg.type}`);
      }
    } catch (error) {
      Logger.error(LogTags.LIVEKIT, 'Failed to handle message', error as Error);
    }
  }

  /**
   * 发送 WebSocket 消息
}
