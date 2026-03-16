// Libsodium Plugin
//
// 加密插件，使用 @ohos.crypto 提供加密功能
//
// 由于 HarmonyOS 使用 @ohos.crypto 进行加密操作，
// 本插件封装了系统提供的加密接口，提供兼容 Libsodium 的 API。
//
// 功能：
// - AES-GCM 对称加密/解密
// - SHA-256 哈希计算
// - 密钥生成（对称密钥、随机数）

import { Logger, LogTags } from '../utils/Logger';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

/**
 * 加密算法枚举
 */
export enum CryptoAlgorithm {
  AES128_GCM = 'AES128_GCM',
  AES256_GCM = 'AES256_GCM',
  SHA256 = 'SHA256',
  SHA384 = 'SHA384',
  SHA512 = 'SHA512',
  HMAC_SHA256 = 'HMAC_SHA256'
}

/**
 * 密钥对（保留接口兼容性，非对称加密使用其他方式）
 */
export interface KeyPair {
  publicKey: string;   // Base64 编码
  secretKey: string;   // Base64 编码
}

/**
 * Libsodium Plugin 类
 */
