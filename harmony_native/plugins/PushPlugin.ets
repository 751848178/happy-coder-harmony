import { PushPluginNotification } from './PushPluginNotification';

export class PushPlugin extends PushPluginNotification {
  dispose(): void {
    Logger.debug(LogTags.PUSH, 'Disposing Push Plugin');

    this.unregisterPushCallbacks();

    if (this.pushService) {
      this.pushService = null;
    }

    this.isInitialized = false;
    this.eventStream = [];
    this.initialMessage = null;
  }
}

/**
 * Push 管理器（单例）
 */
class PushManager {
}

class PushManager {
  private static instance: PushPlugin;

  static getInstance(): PushPlugin {
    if (!PushManager.instance) {
      PushManager.instance = new PushPlugin();
    }
    return PushManager.instance;
  }
}

export const pushPlugin = PushManager.getInstance();
export default PushPlugin;
