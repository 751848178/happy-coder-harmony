import { Logger, LogTags } from '../utils/Logger';
import { DevicePluginInteraction } from './DevicePluginInteraction';

export class DevicePlugin extends DevicePluginInteraction {
  dispose(): void {
    Logger.debug(LogTags.DEVICE, 'Disposing Device Plugin');

    this.offNetworkStatusChange();
    this.offBatteryChange();

    if (this.netConnection) {
      this.netConnection.unregisterNetConnection();
      this.netConnection = null;
    }

    this.deviceInfoCache = null;
    this.networkStatusCache = null;
  }
}

class DeviceManager {
  private static instance: DevicePlugin;

  static getInstance(): DevicePlugin {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DevicePlugin();
    }
    return DeviceManager.instance;
  }
}

export const devicePlugin = DeviceManager.getInstance();
