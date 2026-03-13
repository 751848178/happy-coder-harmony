// Logger Utility
//
// 日志工具类，提供统一的日志输出功能
//
// 功能：
// - 支持不同级别的日志输出 (debug, info, warn, error)
// - 支持标签过滤
// - 支持日志持久化（可选）

/**
 * 日志级别枚举
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  NONE = 4
}

/**
 * 日志标签配置
 */
const LOG_TAGS = {
  DEFAULT: '[HappyCoder]',
  LIVEKIT: '[LiveKit]',
  LIBSODIUM: '[Libsodium]',
  PUSH: '[Push]',
  QR: '[QR]',
  FILE: '[File]',
  DEVICE: '[Device]',
  BRIDGE: '[Bridge]'
};

/**
 * 当前日志级别，可通过 setLevel 动态调整
 */
let currentLogLevel: LogLevel = LogLevel.DEBUG;

/**
 * Logger 类
 */
export class Logger {
  /**
   * 设置日志级别
   * @param level 日志级别
   */
  static setLevel(level: LogLevel): void {
    currentLogLevel = level;
  }

  /**
   * 获取当前日志级别
   * @returns 当前日志级别
   */
  static getLevel(): LogLevel {
    return currentLogLevel;
  }

  /**
   * Debug 级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  static debug(tag: string = LOG_TAGS.DEFAULT, message: string): void {
    if (currentLogLevel <= LogLevel.DEBUG) {
      console.debug(`${tag} ${message}`);
    }
  }

  /**
   * Info 级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  static info(tag: string = LOG_TAGS.DEFAULT, message: string): void {
    if (currentLogLevel <= LogLevel.INFO) {
      console.info(`${tag} ${message}`);
    }
  }

  /**
   * Warn 级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  static warn(tag: string = LOG_TAGS.DEFAULT, message: string): void {
    if (currentLogLevel <= LogLevel.WARN) {
      console.warn(`${tag} ${message}`);
    }
  }

  /**
   * Error 级别日志
   * @param tag 日志标签
   * @param message 日志消息
   * @param error 错误对象（可选）
   */
  static error(tag: string = LOG_TAGS.DEFAULT, message: string, error?: Error): void {
    if (currentLogLevel <= LogLevel.ERROR) {
      console.error(`${tag} ${message}`, error);
    }
  }

  /**
   * 打印对象信息（Debug 模式下）
   * @param tag 日志标签
   * @param object 要打印的对象
   * @param label 对象标签
   */
  static object(tag: string = LOG_TAGS.DEFAULT, object: Object, label: string = 'Object'): void {
    if (currentLogLevel <= LogLevel.DEBUG) {
      console.debug(`${tag} ${label}:`, JSON.stringify(object));
    }
  }

  /**
   * 输出分隔线
   * @param tag 日志标签
   * @param title 分隔线标题
   */
  static divider(tag: string = LOG_TAGS.DEFAULT, title: string = ''): void {
    if (currentLogLevel <= LogLevel.DEBUG) {
      const line = '═'.repeat(40);
      if (title) {
        console.debug(`${tag} ${line} ${title} ${line}`);
      } else {
        console.debug(`${tag} ${line}`);
      }
    }
  }
}

/**
 * 标签快捷访问
 */
export const LogTags = LOG_TAGS;
