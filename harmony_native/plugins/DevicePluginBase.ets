import { Logger, LogTags } from '../utils/Logger';
import deviceInfo from '@ohos.deviceInfo';
import connection from '@ohos.net.connection';
import batteryInfo from '@ohos.batteryInfo';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import pasteboard from '@ohos.pasteboard';
import geoLocationManager from '@ohos.geoLocationManager';
import common from '@ohos.app.ability.common';
import { BatteryChargingStatus, NetworkType, PermissionType } from './DevicePluginModels';

export class DevicePluginBase {
  protected deviceInfoCache: DeviceInfo | null = null;
  protected networkStatusCache: NetworkStatus | null = null;
  protected netConnection: connection.NetConnection | null = null;
  protected batteryCallbackId: number = -1;
  protected atManager: abilityAccessCtrl.AtManager | null = null;
  protected abilityContext: common.Context | null = null;

  constructor() {
    Logger.debug(LogTags.DEVICE, 'Device Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
    this.abilityContext = context;
    this.atManager = abilityAccessCtrl.createAtManager(context);
  protected async getCurrentNetworkType(): Promise<connection.NetCap> {
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
  protected convertToNetworkType(netCap: connection.NetCap): NetworkType {
    switch (netCap) {
      case connection.NetCap.NET_CAP_WIFI:
        return NetworkType.WIFI;
      case connection.NetCap.NET_CAP_CELLULAR:
        return NetworkType.CELLULAR;
      case connection.NetCap.NET_CAP_ETHERNET:
        return NetworkType.ETHERNET;
      case connection.NetCap.NET_CAP_BLUETOOTH:
        return NetworkType.BLUETOOTH;
      case connection.NetCap.NET_CAP_VPN:
        return NetworkType.VPN;
      case connection.NetCap.NET_CAP_NONE:
      default:
        return NetworkType.NONE;
    }
  }

  /**
   * 获取网络类型名称
   */
  protected getNetworkTypeName(type: NetworkType): string {
    switch (type) {
      case NetworkType.WIFI:
        return 'wifi';
      case NetworkType.CELLULAR:
        return 'cellular';
      case NetworkType.ETHERNET:
        return 'ethernet';
      case NetworkType.BLUETOOTH:
        return 'bluetooth';
      case NetworkType.VPN:
        return 'vpn';
      case NetworkType.NONE:
      default:
        return 'none';
    }
  }

  /**
   * 获取信号强度
   */
  protected getSignalStrength(capabilities: connection.NetCapabilities, networkType: NetworkType): number {
    if (networkType === NetworkType.NONE) {
      return 0;
    }

    // 尝试从 capabilities 中获取信号强度
    if (capabilities.signalStrength) {
      // 将信号强度转换为 0-100 的范围
      return Math.min(100, Math.max(0, capabilities.signalStrength));
    }

    // 默认返回合理的值
    return networkType === NetworkType.WIFI ? 85 : 70;
  }

  /**
   * 获取充电类型名称
   */
  protected getChargingTypeName(status: BatteryChargingStatus): string {
    switch (status) {
      case BatteryChargingStatus.NONE:
        return 'none';
      case BatteryChargingStatus.ENABLE:
        return 'charging';
      case BatteryChargingStatus.DISABLE:
        return 'discharging';
      case BatteryChargingStatus.FULL:
        return 'full';
      default:
        return 'unknown';
    }
  }

  /**
   * 请求单个权限
   */
  protected async requestPermission(permission: PermissionType): Promise<boolean> {
    Logger.info(LogTags.DEVICE, `Requesting permission: ${permission}`);

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const result = await atManager.requestPermissionsFromUser(this.abilityContext, [permission]);

      const granted = result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      Logger.info(LogTags.DEVICE, `Permission ${permission}: ${granted ? 'granted' : 'denied'}`);
      return granted;
    } catch (error) {
      Logger.error(LogTags.DEVICE, `Permission request failed: ${permission}`, error as Error);
      return false;
    }
  }
}
