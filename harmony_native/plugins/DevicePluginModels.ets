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
