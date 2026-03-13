// Device Plugin
//
// 设备信息和权限管理插件
//
// 功能：
// - 获取设备信息
// - 获取网络状态
// - 获取电池状态
// - 请求系统权限
// - 剪贴板操作

import { Logger, LogTags } from '../utils/Logger';
import deviceInfo from '@ohos.deviceInfo';
import connection from '@ohos.net.connection';
import batteryInfo from '@ohos.batteryInfo';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import pasteboard from '@ohos.pasteboard';
import geoLocationManager from '@ohos.geoLocationManager';
import common from '@ohos.app.ability.common';

/**
 * 设备信息
 */
export interface DeviceInfo {
  model: string;            // 设备型号
  brand: string;            // 品牌
  osVersion: string;        // 系统版本
  apiLevel: number;         // API 级别
  deviceId: string;          // 设备 ID
  productName: string;      // 产品名称
  manufacturer: string;     // 制造商
  platform: string;         // 平台 (harmonyos)
  buildVersion: string;     // 构建版本
  softwareModel: string;    // 软件模型
  udid: string;             // 唯一设备标识
}

/**
 * 网络类型
 */
export enum NetworkType {
  NONE = 'none',
  WIFI = 'wifi',
  CELLULAR = 'cellular',
  ETHERNET = 'ethernet',
  VPN = 'vpn',
  BLUETOOTH = 'bluetooth',
  UNKNOWN = 'unknown'
}

/**
 * 网络状态
 */
export interface NetworkStatus {
  type: NetworkType;        // 网络类型
  isConnected: boolean;     // 是否已连接
  isOnline: boolean;       // 是否在线
  signalStrength: number;  // 信号强度 (0-100)
  netId: number;           // 网络标识
  typeName: string;        // 网络类型名称
}

/**
 * 电池信息
 */
export interface BatteryInfo {
  level: number;            // 电量 (0-100)
  isCharging: boolean;      // 是否在充电
  isFull: boolean;          // 是否已充满
  isLow: boolean;           // 是否低电量
  chargingType: string;     // 充电类型
  health: number;           // 电池健康度
  temperature: number;      // 电池温度 (摄氏度)
}

/**
 * 权限类型
 */
export enum PermissionType {
  CAMERA = 'ohos.permission.CAMERA',
  MICROPHONE = 'ohos.permission.MICROPHONE',
  READ_MEDIA = 'ohos.permission.READ_MEDIA',
  WRITE_MEDIA = 'ohos.permission.WRITE_MEDIA',
  READ_MEDIA_VIDEO = 'ohos.permission.READ_MEDIA_VIDEO',
  READ_MEDIA_IMAGE = 'ohos.permission.READ_MEDIA_IMAGE',
  READ_MEDIA_AUDIO = 'ohos.permission.READ_MEDIA_AUDIO',
  APPROXIMATELY_LOCATION = 'ohos.permission.APPROXIMATELY_LOCATION',
  LOCATION = 'ohos.permission.LOCATION',
  INTERNET = 'ohos.permission.INTERNET',
  GET_NETWORK_INFO = 'ohos.permission.GET_NETWORK_INFO',
  ACTIVITY_MOTION = 'ohos.permission.ACTIVITY_MOTION'
}

/**
 * 权限状态
 */
export enum PermissionStatus {
  GRANTED = 0,
  DENIED = -1,
  NOT_DETERMINED = -2
}

/**
 * 位置信息
 */
export interface LocationInfo {
  latitude: number;         // 纬度
  longitude: number;        // 经度
  accuracy: number;         // 精度
  altitude?: number;        // 海拔
  heading?: number;         // 方向
  speed?: number;           // 速度
  timestamp: number;       // 时间戳
}

/**
 * Location Request 配置
 */
export interface LocationRequestConfig {
  scenario: LocationScenario;  // 定位场景
  priority: LocationPriority;    // 定位优先级
  timeInterval?: number;        // 定位间隔 (毫秒)
  distanceInterval?: number;    // 定位距离 (米)
  maxAccuracy?: number;         // 最大精度
}

/**
 * 定位场景
 */
export enum LocationScenario {
  UNSET = 0x300,              // 未设置
  DAILY_LIFE_SERVICE = 0x301, // 日常生活
  EMERGENCY_CALL = 0x302,     // 紧急呼叫
  AUTOMOTIVE_NAVIGATION = 0x303, // 车载导航
  TRAJECTORY_TRACKING = 0x304, // 轨迹追踪
  TRANSPORTATION = 0x305,     // 交通运输
}

/**
 * 定位优先级
 */
export enum LocationPriority {
  LOW_POWER = 0x200,      // 低功耗
  ACCURACY = 0x201,       // 高精度
  FIRST_FIX = 0x202       // 快速定位
}

/**
 * 电池充电状态
 */
enum BatteryChargingStatus {
  NONE = 0,
  ENABLE = 1,
  DISABLE = 2,
  FULL = 3
}

/**
 * 电池健康状态
 */
enum BatteryHealthStatus {
  UNKNOWN = 0,
  GOOD = 1,
  OVERHEAT = 2,
  OVER_VOLTAGE = 3,
  UNSPECIFIED_FAILURE = 4,
  COLD = 5
}

/**
 * Device Plugin 类
 */
export class DevicePlugin {
  private deviceInfoCache: DeviceInfo | null = null;
  private networkStatusCache: NetworkStatus | null = null;
  private netConnection: connection.NetConnection | null = null;
  private batteryCallbackId: number = -1;
  private atManager: abilityAccessCtrl.AtManager | null = null;
  private abilityContext: common.Context | null = null;

  constructor() {
    Logger.debug(LogTags.DEVICE, 'Device Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
    this.abilityContext = context;
    this.atManager = abilityAccessCtrl.createAtManager(context);
  }

  // ========== 设备信息 ==========

  /**
   * 获取设备信息
   * @returns 设备信息
   */
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
    Logger.debug(LogTags.DEVICE, 'Unregistering network status listener');

    if (this.netConnection) {
      this.netConnection.off('netAvailable');
      this.netConnection.off('netLost');
    }
  }

  // ========== 电池信息 ==========

  /**
   * 获取电池信息
   * @returns 电池信息
   */
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

  // ========== 权限管理 ==========

  /**
   * 请求相机权限
   * @returns 是否获得权限
   */
  async requestCameraPermission(): Promise<boolean> {
    return this.requestPermission(PermissionType.CAMERA);
  }

  /**
   * 请求麦克风权限
   * @returns 是否获得权限
   */
  async requestMicrophonePermission(): Promise<boolean> {
    return this.requestPermission(PermissionType.MICROPHONE);
  }

  /**
   * 请求存储权限（使用媒体权限）
   * @returns 是否获得权限
   */
  async requestStoragePermission(): Promise<boolean> {
    // 鸿蒙 NEXT 不再需要存储权限，改用媒体权限
    return await this.requestPermission(PermissionType.READ_MEDIA_IMAGE);
  }

  /**
   * 请求位置权限
   * @returns 是否获得权限
   */
  async requestLocationPermission(): Promise<boolean> {
    // 先请求大概位置权限
    const approxResult = await this.requestPermission(PermissionType.APPROXIMATELY_LOCATION);
    return approxResult;
  }

  /**
   * 请求多个权限
   * @param permissions 权限列表
   * @returns 权限状态映射
   */
  async requestMultiplePermissions(permissions: PermissionType[]): Promise<Map<PermissionType, boolean>> {
    Logger.info(LogTags.DEVICE, `Requesting ${permissions.length} permissions`);

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      const resultMap = new Map<PermissionType, boolean>();
      permissions.forEach(perm => resultMap.set(perm, false));
      return resultMap;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const results = await atManager.requestPermissionsFromUser(this.abilityContext, permissions);

      const resultMap = new Map<PermissionType, boolean>();
      permissions.forEach((perm, index) => {
        const granted = results.authResults[index] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        resultMap.set(perm, granted);
        Logger.debug(LogTags.DEVICE, `Permission ${perm}: ${granted ? 'granted' : 'denied'}`);
      });

      return resultMap;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to request permissions', error as Error);
      const resultMap = new Map<PermissionType, boolean>();
      permissions.forEach(perm => resultMap.set(perm, false));
      return resultMap;
    }
  }

  /**
   * 检查权限状态
   * @param permission 权限类型
   * @returns 权限状态
   */
  async checkPermission(permission: PermissionType): Promise<PermissionStatus> {
    Logger.debug(LogTags.DEVICE, `Checking permission: ${permission}`);

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      return PermissionStatus.NOT_DETERMINED;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager(this.abilityContext);
      const status = await atManager.checkAccessToken(this.abilityContext.applicationInfo.accessTokenId, permission);

      const permissionStatus = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        ? PermissionStatus.GRANTED
        : PermissionStatus.DENIED;

      Logger.debug(LogTags.DEVICE, `Permission ${permission} status: ${permissionStatus}`);
      return permissionStatus;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to check permission', error as Error);
      return PermissionStatus.NOT_DETERMINED;
    }
  }

  /**
   * 打开应用设置页面
   */
  async openAppSettings(): Promise<void> {
    Logger.info(LogTags.DEVICE, 'Opening app settings');

    if (!this.abilityContext) {
      Logger.error(LogTags.DEVICE, 'Ability context not set');
      throw new Error('Ability context not set');
    }

    try {
      const bundleInfo = await this.abilityContext.bundleManager.getBundleInfoForSelf(
        this.abilityContext.bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );

      const want: Want = {
        bundleName: bundleInfo.appInfo.name,
        abilityName: 'com.huawei.settings.MainAbility'
      };

      await this.abilityContext.startAbility(want);
      Logger.debug(LogTags.DEVICE, 'App settings opened');
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to open app settings', error as Error);
      // 备选方案：打开通用设置
      try {
        const want: Want = {
          bundleName: 'com.huawei.settings',
          abilityName: 'com.huawei.settings.MainAbility'
        };
        await this.abilityContext.startAbility(want);
      } catch (e) {
        Logger.error(LogTags.DEVICE, 'Failed to open settings', e as Error);
        throw new Error('Unable to open settings');
      }
    }
  }

  // ========== 剪贴板操作 ==========

  /**
   * 设置剪贴板内容
   * @param text 要复制的文本
   * @returns 是否成功
   */
  async setClipboard(text: string): Promise<boolean> {
    Logger.debug(LogTags.DEVICE, `Setting clipboard: ${text.substring(0, 20)}...`);

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await systemPasteboard.setData(pasteData);

      Logger.debug(LogTags.DEVICE, 'Clipboard set successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to set clipboard', error as Error);
      return false;
    }
  }

  /**
   * 获取剪贴板内容
   * @returns 剪贴板文本
   */
  async getClipboard(): Promise<string | null> {
    Logger.debug(LogTags.DEVICE, 'Getting clipboard content');

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = await systemPasteboard.getData();
      const text = pasteData.getPrimaryText();

      Logger.debug(LogTags.DEVICE, `Clipboard content: ${text ? text.substring(0, 20) : '(empty)'}...`);
      return text || null;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get clipboard', error as Error);
      return null;
    }
  }

  /**
   * 清空剪贴板
   * @returns 是否成功
   */
  async clearClipboard(): Promise<boolean> {
    Logger.debug(LogTags.DEVICE, 'Clearing clipboard');

    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.clearData();

      Logger.debug(LogTags.DEVICE, 'Clipboard cleared successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to clear clipboard', error as Error);
      return false;
    }
  }

  // ========== 位置信息 ==========

  /**
   * 获取当前位置
   * @param config 定位配置
   * @returns 位置信息
   */
  async getCurrentLocation(config?: LocationRequestConfig): Promise<LocationInfo> {
    Logger.debug(LogTags.DEVICE, 'Getting current location');

    try {
      // 先检查位置权限
      const hasPermission = await this.checkPermission(PermissionType.APPROXIMATELY_LOCATION);
      if (!hasPermission) {
        Logger.warn(LogTags.DEVICE, 'No location permission');
        throw new Error('No location permission');
      }

      const requestConfig: geoLocationManager.LocationRequest = {
        scenario: config?.scenario ?? LocationScenario.DAILY_LIFE_SERVICE,
        priority: config?.priority ?? LocationPriority.FIRST_FIX,
        timeInterval: config?.timeInterval ?? 1,
        distanceInterval: config?.distanceInterval ?? 0,
        maxAccuracy: config?.maxAccuracy ?? 0
      };

      const location = await geoLocationManager.getCurrentLocation(requestConfig);

      const info: LocationInfo = {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude,
        heading: location.direction,
        speed: location.speed,
        timestamp: location.timeStamp
      };

      Logger.debug(LogTags.DEVICE, `Location: ${JSON.stringify(info)}`);
      return info;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to get location', error as Error);
      throw error;
    }
  }

  /**
   * 启用连续位置更新
   * @param config 定位配置
   * @param callback 位置更新回调
   */
  async enableLocationUpdates(
    config: LocationRequestConfig,
    callback: (location: LocationInfo) => void
  ): Promise<number> {
    Logger.debug(LogTags.DEVICE, 'Enabling location updates');

    try {
      const requestConfig: geoLocationManager.LocationRequest = {
        scenario: config.scenario ?? LocationScenario.DAILY_LIFE_SERVICE,
        priority: config.priority ?? LocationPriority.FIRST_FIX,
        timeInterval: config.timeInterval ?? 1000,
        distanceInterval: config.distanceInterval ?? 0,
        maxAccuracy: config.maxAccuracy ?? 0
      };

      const callbackId = geoLocationManager.on('locationChange', requestConfig, (location) => {
        const info: LocationInfo = {
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          altitude: location.altitude,
          heading: location.direction,
          speed: location.speed,
          timestamp: location.timeStamp
        };
        callback(info);
      });

      Logger.info(LogTags.DEVICE, `Location updates enabled, callbackId: ${callbackId}`);
      return callbackId;
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to enable location updates', error as Error);
      throw error;
    }
  }

  /**
   * 禁用连续位置更新
   * @param callbackId 回调 ID
   */
  disableLocationUpdates(callbackId: number): void {
    Logger.debug(LogTags.DEVICE, `Disabling location updates: ${callbackId}`);

    try {
      geoLocationManager.off('locationChange', callbackId);
      Logger.info(LogTags.DEVICE, 'Location updates disabled');
    } catch (error) {
      Logger.error(LogTags.DEVICE, 'Failed to disable location updates', error as Error);
    }
  }

  // ========== 工具方法 ==========

  /**
   * 测试通道是否可用
   */
  async ping(): Promise<boolean> {
    return true;
  }

  /**
   * 转换网络类型
   */
  private convertToNetworkType(netCap: connection.NetCap): NetworkType {
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
  private getNetworkTypeName(type: NetworkType): string {
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
  private getSignalStrength(capabilities: connection.NetCapabilities, networkType: NetworkType): number {
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
  private getChargingTypeName(status: BatteryChargingStatus): string {
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
  private async requestPermission(permission: PermissionType): Promise<boolean> {
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

  /**
   * 清理资源
   */
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

/**
 * Device 管理器（单例）
 */
class DeviceManager {
  private static instance: DevicePlugin;

  static getInstance(): DevicePlugin {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DevicePlugin();
    }
    return DeviceManager.instance;
  }
}

/**
 * 导出单例实例
 */
export const devicePlugin = DeviceManager.getInstance();
