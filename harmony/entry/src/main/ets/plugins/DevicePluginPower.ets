import { Logger, LogTags } from '../utils/Logger';
import batteryInfo from '@ohos.batteryInfo';
import { BatteryInfo, BatteryChargingStatus } from './DevicePluginModels';
import { DevicePluginIdentityNetwork } from './DevicePluginIdentityNetwork';

export class DevicePluginPower extends DevicePluginIdentityNetwork {
  async getBatteryInfo(): Promise<BatteryInfo> {
    Logger.debug(LogTags.DEVICE, 'Getting battery info');

    try {
      const level = batteryInfo.batteryLevel;
      const chargingStatus = batteryInfo.chargingStatus;
      const isCharging = chargingStatus === BatteryChargingStatus.ENABLE ||
                        chargingStatus === BatteryChargingStatus.FULL;

      const info: BatteryInfo = {
        level: level,
        isCharging: isCharging,
        isFull: chargingStatus === BatteryChargingStatus.FULL,
        isLow: level <= 20,
        chargingType: this.getChargingTypeName(chargingStatus),
        health: batteryInfo.healthStatus,
        temperature: batteryInfo.batteryTemperature
      };

      Logger.debug(LogTags.DEVICE, `Battery info: ${JSON.stringify(info)}`);
      return info;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get battery info', error as Error);
      throw error;
    }
  }

  /**
   * 监听电池状态变化
   * @param callback 状态变化回调
   */
  onBatteryChange(callback: (info: BatteryInfo) => void): void {
    Logger.debug(LogTags.DEVICE, 'Registering battery change listener');

    // 获取当前电池信息
    this.getBatteryInfo().then(callback);

    // 监听电池电量变化
    this.batteryCallbackId = batteryInfo.on('batteryStatus', (data) => {
      Logger.debug(LogTags.DEVICE, `Battery status changed: ${JSON.stringify(data)}`);
      this.getBatteryInfo().then(callback);
    });
  }

  /**
   * 取消监听电池状态变化
   */
  offBatteryChange(): void {
    Logger.debug(LogTags.DEVICE, 'Unregistering battery change listener');

    if (this.batteryCallbackId !== -1) {
      batteryInfo.off('batteryStatus', this.batteryCallbackId);
      this.batteryCallbackId = -1;
    }
  }
}
