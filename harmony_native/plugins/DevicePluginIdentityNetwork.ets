import { Logger, LogTags } from '../utils/Logger';
import deviceInfo from '@ohos.deviceInfo';
import connection from '@ohos.net.connection';
import { DeviceInfo, NetworkStatus, NetworkType } from './DevicePluginModels';
import { DevicePluginBase } from './DevicePluginBase';

export class DevicePluginIdentityNetwork extends DevicePluginBase {
  async getDeviceInfo(): Promise<DeviceInfo> {
    Logger.debug(LogTags.DEVICE, 'Getting device info');

    if (this.deviceInfoCache) {
      return this.deviceInfoCache;
    }

    try {
      const info: DeviceInfo = {
        model: deviceInfo.deviceType,
        brand: deviceInfo.brand,
        osVersion: deviceInfo.displayVersion,
        apiLevel: parseInt(deviceInfo.sdkApiVersion || '0'),
        deviceId: deviceInfo.udid,
        productName: deviceInfo.productSeries,
        manufacturer: deviceInfo.manufacture,
        platform: 'harmonyos',
        buildVersion: deviceInfo.incrementalVersion,
        softwareModel: deviceInfo.softwareModel,
        udid: deviceInfo.udid
      };

      this.deviceInfoCache = info;
      Logger.debug(LogTags.DEVICE, `Device info: ${JSON.stringify(info)}`);

      return info;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get device info', error as Error);
      throw error;
    }
  }

  // ========== 网络状态 ==========

  /**
   * 获取网络状态
   * @returns 网络状态
   */
  async getNetworkStatus(): Promise<NetworkStatus> {
    Logger.debug(LogTags.DEVICE, 'Getting network status');

    try {
      if (!this.netConnection) {
        this.netConnection = connection.createNetConnection();
      }

      const netHandle = this.netConnection;
      const netType = await this.getCurrentNetworkType();
      const netCapabilities = await netHandle.getNetCapabilities();

      const networkType = this.convertToNetworkType(netType);
      const isConnected = networkType !== NetworkType.NONE;

      const status: NetworkStatus = {
        type: networkType,
        isConnected: isConnected,
        isOnline: isConnected,
        signalStrength: this.getSignalStrength(netCapabilities, networkType),
        netId: netHandle.netId,
        typeName: this.getNetworkTypeName(networkType)
      };

      this.networkStatusCache = status;
      Logger.debug(LogTags.DEVICE, `Network status: ${JSON.stringify(status)}`);

      return status;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get network status', error as Error);
      // 返回默认网络状态
      return {
        type: NetworkType.UNKNOWN,
        isConnected: false,
        isOnline: false,
        signalStrength: 0,
        netId: 0,
        typeName: 'unknown'
      };
    }
  }

  /**
   * 获取当前网络类型
   */
  private async getCurrentNetworkType(): Promise<connection.NetCap> {
    if (!this.netConnection) {
      this.netConnection = connection.createNetConnection();
    }

    try {
      const capabilities = await this.netConnection.getNetCapabilities();
      if (capabilities.bearerTypes) {
        return capabilities.bearerTypes[0] as connection.NetCap;
      }
    } catch (error) {
      Logger.warn(LogTags.DEVICE, 'Failed to get network type', error as Error);
    }
    return connection.NetCap.NET_CAP_NONE;
  }

  /**
   * 监听网络状态变化
   * @param callback 状态变化回调
   */
  onNetworkStatusChange(callback: (status: NetworkStatus) => void): void {
    Logger.debug(LogTags.DEVICE, 'Registering network status listener');

    if (!this.netConnection) {
      this.netConnection = connection.createNetConnection();
    }

    this.netConnection.on('netAvailable', (netHandle) => {
      Logger.debug(LogTags.DEVICE, `Network available: ${netHandle.netId}`);
      this.getNetworkStatus().then(callback);
    });

    this.netConnection.on('netLost', (netHandle) => {
      Logger.debug(LogTags.DEVICE, `Network lost: ${netHandle.netId}`);
      callback({
        type: NetworkType.NONE,
        isConnected: false,
        isOnline: false,
        signalStrength: 0,
        netId: netHandle.netId,
        typeName: 'none'
      });
    });
  }

  /**
   * 取消监听网络状态变化
   */
  offNetworkStatusChange(): void {
}
