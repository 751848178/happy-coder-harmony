import { LiveKitPluginAudio } from './LiveKitPluginAudio';

export class LiveKitPlugin extends LiveKitPluginAudio {
  dispose(): void {
    Logger.debug(LogTags.LIVEKIT, 'Disposing LiveKit Plugin');

    this.disconnect();
    this.eventCallbacks = {};
  }
}

/**
 * LiveKit 管理器（单例）
}

class LiveKitManager {
  private static instance: LiveKitPlugin;

  static getInstance(): LiveKitPlugin {
    if (!LiveKitManager.instance) {
      LiveKitManager.instance = new LiveKitPlugin();
    }
    return LiveKitManager.instance;
  }
}

export const liveKitPlugin = LiveKitManager.getInstance();
export default LiveKitPlugin;
