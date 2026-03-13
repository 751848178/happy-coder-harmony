// Conversion Utility
//
// 数据转换工具类，提供各种数据格式转换功能
//
// 功能：
// - ArrayBuffer 与 Base64 互转
// - ArrayBuffer 与 Hex 互转
// - Uint8Array 处理
// - 字符串编码转换

import { Logger, LogTags } from './Logger';

/**
 * 数据转换工具类
 */
export class Conversion {
  /**
   * ArrayBuffer 转 Base64 字符串
   * @param buffer ArrayBuffer 数据
   * @returns Base64 编码字符串
   */
  static arrayBufferToBase64(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < uint8Array.byteLength; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * Base64 字符串转 ArrayBuffer
   * @param base64 Base64 编码字符串
   * @returns ArrayBuffer 数据
   */
  static base64ToArrayBuffer(base64: string): ArrayBuffer {
    const binary = atob(base64);
    const length = binary.length;
    const buffer = new ArrayBuffer(length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < length; i++) {
      uint8Array[i] = binary.charCodeAt(i);
    }
    return buffer;
  }

  /**
   * Base64 字符串转 Uint8Array
   * @param base64 Base64 编码字符串
   * @returns Uint8Array 数组
   */
  static base64ToUint8Array(base64: string): Uint8Array {
    return new Uint8Array(this.base64ToArrayBuffer(base64));
  }

  /**
   * Uint8Array 转 Base64 字符串
   * @param uint8Array Uint8Array 数组
   * @returns Base64 编码字符串
   */
  static uint8ArrayToBase64(uint8Array: Uint8Array): string {
    return this.arrayBufferToBase64(uint8Array.buffer);
  }

  /**
   * ArrayBuffer 转 Hex 字符串
   * @param buffer ArrayBuffer 数据
   * @returns Hex 字符串
   */
  static arrayBufferToHex(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer);
    let hex = '';
    for (let i = 0; i < uint8Array.length; i++) {
      hex += uint8Array[i].toString(16).padStart(2, '0');
    }
    return hex;
  }

  /**
   * Hex 字符串转 ArrayBuffer
   * @param hex Hex 字符串
   * @returns ArrayBuffer 数据
   */
  static hexToArrayBuffer(hex: string): ArrayBuffer {
    const length = hex.length / 2;
    const buffer = new ArrayBuffer(length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < length; i++) {
      uint8Array[i] = parseInt(hex.substr(i * 2, 2), 16);
    }
    return buffer;
  }

  /**
   * 字符串转 Uint8Array (UTF-8 编码)
   * @param str 字符串
   * @returns Uint8Array 数组
   */
  static stringToUint8Array(str: string): Uint8Array {
    const encoder = new TextEncoder();
    return new Uint8Array(encoder.encodeInto(str).buffer || new ArrayBuffer(0));
  }

  /**
   * Uint8Array 转字符串 (UTF-8 解码)
   * @param uint8Array Uint8Array 数组
   * @returns 解码后的字符串
   */
  static uint8ArrayToString(uint8Array: Uint8Array): string {
    const decoder = new TextDecoder();
    return decoder.decode(uint8Array);
  }

  /**
   * 合并多个 Uint8Array
   * @param arrays Uint8Array 数组列表
   * @returns 合并后的 Uint8Array
   */
  static concatUint8Arrays(...arrays: Uint8Array[]): Uint8Array {
    const totalLength = arrays.reduce((sum, arr) => sum + arr.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const arr of arrays) {
      result.set(arr, offset);
      offset += arr.length;
    }
    return result;
  }

  /**
   * 比较两个 ArrayBuffer 是否相等
   * @param a ArrayBuffer a
   * @param b ArrayBuffer b
   * @returns 是否相等
   */
  static arrayBuffersEqual(a: ArrayBuffer, b: ArrayBuffer): boolean {
    if (a.byteLength !== b.byteLength) {
      return false;
    }
    const viewA = new Uint8Array(a);
    const viewB = new Uint8Array(b);
    for (let i = 0; i < viewA.length; i++) {
      if (viewA[i] !== viewB[i]) {
        return false;
      }
    }
    return true;
  }

  /**
   * 将数据转换为适合传输的格式
   * @param data 输入数据（字符串、ArrayBuffer、Uint8Array）
   * @returns Base64 字符串
   */
  static toBase64(data: string | ArrayBuffer | Uint8Array): string {
    if (typeof data === 'string') {
      return btoa(data);
    } else if (data instanceof Uint8Array) {
      return this.uint8ArrayToBase64(data);
    } else {
      return this.arrayBufferToBase64(data);
    }
  }

  /**
   * 从 Base64 解析数据
   * @param base64 Base64 字符串
   * @param outputFormat 输出格式：'arraybuffer' | 'uint8array' | 'string'
   * @returns 解析后的数据
   */
  static fromBase64(base64: string, outputFormat: 'arraybuffer' | 'uint8array' | 'string' = 'arraybuffer'): ArrayBuffer | Uint8Array | string {
    try {
      switch (outputFormat) {
        case 'arraybuffer':
          return this.base64ToArrayBuffer(base64);
        case 'uint8array':
          return this.base64ToUint8Array(base64);
        case 'string':
          return atob(base64);
        default:
          return this.base64ToArrayBuffer(base64);
      }
    } catch (e) {
      Logger.error(LogTags.BRIDGE, 'Failed to decode Base64', e as Error);
      throw new Error('Invalid Base64 data');
    }
  }
}
