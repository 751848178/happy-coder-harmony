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
export class LibsodiumPlugin {
  private readonly KEY_SIZE_256 = 32;     // 256 bits
  private readonly KEY_SIZE_128 = 16;     // 128 bits
  private readonly NONCE_SIZE = 12;       // 96 bits (GCM 标准)
  private readonly AES_TAG_SIZE = 16;    // 128 bits

  constructor() {
    Logger.debug(LogTags.LIBSODIUM, 'Libsodium Plugin initialized');
  }

  // ========== 密钥生成 ==========

  /**
   * 生成加密密钥 (256-bit)
   * @returns Base64 编码的密钥
   */
  async generateKey(): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, 'Generating encryption key');

    try {
      // 使用随机数生成器生成密钥
      const randomBuffer = new Uint8Array(this.KEY_SIZE_256);

      // 使用 cryptoFramework 生成随机数
      const generator = cryptoFramework.createRandom();
      await generator.generateRandom(this.KEY_SIZE_256);
      const randomBytes = new Uint8Array(generator.getRandomBytes());

      // 转换为 Base64
      const base64Key = this.uint8ArrayToBase64(randomBytes);
      Logger.debug(LogTags.LIBSODIUM, `Generated key: ${base64Key.substring(0, 16)}...`);

      return base64Key;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Failed to generate key', error as Error);
      throw new Error(`Key generation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 生成密钥对 (使用 RSA)
   * 注意：这是为了接口兼容，实际使用 RSA 而非 Ed25519
   * @returns 密钥对 { publicKey, secretKey }
   */
  async generateKeyPair(): Promise<KeyPair> {
    Logger.debug(LogTags.LIBSODIUM, 'Generating key pair');

    try {
      // 使用 RSA 生成密钥对
      const rsaGenerator = cryptoFramework.createAsyKeyGenerator('RSA2048');
      const keyPair = await rsaGenerator.generateKeyPair();

      // 获取公钥和私钥
      const pubKey = keyPair.pubKey;
      const priKey = keyPair.priKey;

      // 导出为 Base64
      const pubKeyBase64 = this.uint8ArrayToBase64(new Uint8Array(pubKey.getEncoded()));
      const priKeyBase64 = this.uint8ArrayToBase64(new Uint8Array(priKey.getEncoded()));

      const keyPairResult: KeyPair = {
        publicKey: pubKeyBase64,
        secretKey: priKeyBase64
      };

      Logger.debug(LogTags.LIBSODIUM, `Generated key pair: public=${pubKeyBase64.substring(0, 16)}...`);
      return keyPairResult;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Failed to generate key pair', error as Error);
      throw new Error(`Key pair generation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 生成随机数
   * @param size 随机数大小 (bytes)
   * @returns Base64 编码的随机数
   */
  async generateRandom(size: number): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, `Generating random: ${size} bytes`);

    try {
      const randomBuffer = new Uint8Array(size);

      // 使用 cryptoFramework 生成随机数
      const generator = cryptoFramework.createRandom();
      await generator.generateRandom(size);
      const randomBytes = new Uint8Array(generator.getRandomBytes());

      return this.uint8ArrayToBase64(randomBytes);
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Failed to generate random', error as Error);
      throw new Error(`Random generation failed: ${(error as Error).message}`);
    }
  }

  // ========== 对称加密/解密 (AES-GCM) ==========

  /**
   * 使用密钥加密数据 (AES-256-GCM)
   * @param data 要加密的字符串
   * @param key Base64 编码的密钥
   * @returns 加密后的数据 (Base64 格式)
   */
  async encrypt(data: string, key: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, `Encrypting data: ${data.substring(0, 20)}...`);

    try {
      const keyBuffer = this.base64ToUint8Array(key);
      const dataBuffer = this.stringToUint8Array(data);

      // 生成 nonce
      const nonce = new Uint8Array(this.NONCE_SIZE);
      const generator = cryptoFramework.createRandom();
      await generator.generateRandom(this.NONCE_SIZE);
      const randomBytes = new Uint8Array(generator.getRandomBytes());
      nonce.set(randomBytes);

      // 使用 AES-GCM 加密
      const ciphertextWithTag = await this.encryptAESGCM(dataBuffer, keyBuffer, nonce);

      // 组合 nonce、ciphertext 和 auth tag
      const combined = this.concatUint8Arrays(nonce, ciphertextWithTag);
      const result = this.uint8ArrayToBase64(combined);

      Logger.debug(LogTags.LIBSODIUM, 'Encryption successful');
      return result;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Encryption failed', error as Error);
      throw new Error(`Encryption failed: ${(error as Error).message}`);
    }
  }

  /**
   * 使用密钥解密数据 (AES-256-GCM)
   * @param encrypted 加密的数据 (Base64 格式，包含 nonce)
   * @param key Base64 编码的密钥
   * @returns 解密后的数据
   */
  async decrypt(encrypted: string, key: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, 'Decrypting data');

    try {
      const keyBuffer = this.base64ToUint8Array(key);
      const combined = this.base64ToUint8Array(encrypted);

      // 提取 nonce、ciphertext 和 auth tag
      const nonce = combined.slice(0, this.NONCE_SIZE);
      const ciphertextWithTag = combined.slice(this.NONCE_SIZE);

      // 使用 AES-GCM 解密
      const plaintext = await this.decryptAESGCM(ciphertextWithTag, keyBuffer, nonce);

      const result = this.uint8ArrayToString(plaintext);
      Logger.debug(LogTags.LIBSODIUM, 'Decryption successful');

      return result;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Decryption failed', error as Error);
      throw new Error(`Decryption failed: ${(error as Error).message}`);
    }
  }

  /**
   * 使用公钥加密
   * 注意：这是使用 RSA 进行加密
   * @param data 要加密的字符串
   * @param publicKey Base64 编码的公钥
   * @returns 加密后的数据
   */
  async encryptForPublicKey(data: string, publicKey: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, 'Encrypting with public key');

    try {
      const publicKeyBuffer = this.base64ToUint8Array(publicKey);
      const dataBuffer = this.stringToUint8Array(data);

      // 导入公钥
      const pubKeyBlob: cryptoFramework.DataBlob = { data: publicKeyBuffer };
      const pubKey = await cryptoFramework.createAsyKeyGenerator('RSA2048_PUB').convertKey(pubKeyBlob, null, null, null, null);

      // 使用 RSA 加密
      const cipher = cryptoFramework.createCipher('RSA2048_PKCS1_OAEP_MD5_SHA256MGF1');
      await cipher.init(cryptoFramework.EncryptMode.ENCRYPT_MODE, pubKey, null);

      const cipherBlob = await cipher.doFinal({ data: dataBuffer });
      const encryptedBase64 = this.uint8ArrayToBase64(new Uint8Array(cipherBlob.data));

      Logger.debug(LogTags.LIBSODIUM, 'Public key encryption successful');
      return encryptedBase64;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Public key encryption failed', error as Error);
      throw new Error(`Public key encryption failed: ${(error as Error).message}`);
    }
  }

  /**
   * 使用私钥解密
   * 注意：这是使用 RSA 进行解密
   * @param encrypted 加密的数据
   * @param secretKey Base64 编码的私钥
   * @returns 解密后的数据
   */
  async decryptFromPublicKey(encrypted: string, secretKey: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, 'Decrypting with private key');

    try {
      const secretKeyBuffer = this.base64ToUint8Array(secretKey);
      const encryptedBuffer = this.base64ToUint8Array(encrypted);

      // 导入私钥
      const priKeyBlob: cryptoFramework.DataBlob = { data: secretKeyBuffer };
      const priKey = await cryptoFramework.createAsyKeyGenerator('RSA2048_PRI').convertKey(null, priKeyBlob, null, null, null);

      // 使用 RSA 解密
      const cipher = cryptoFramework.createCipher('RSA2048_PKCS1_OAEP_MD5_SHA256MGF1');
      await cipher.init(cryptoFramework.DecryptMode.DECRYPT_MODE, priKey, null);

      const cipherBlob = await cipher.doFinal({ data: encryptedBuffer });
      const plaintext = this.uint8ArrayToString(new Uint8Array(cipherBlob.data));

      Logger.debug(LogTags.LIBSODIUM, 'Private key decryption successful');
      return plaintext;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Private key decryption failed', error as Error);
      throw new Error(`Private key decryption failed: ${(error as Error).message}`);
    }
  }

  // ========== 哈希计算 ==========

  /**
   * 计算哈希值 (SHA-256)
   * @param data 要计算哈希的数据
   * @returns Base64 编码的哈希值
   */
  async hash(data: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, `Computing hash: ${data.substring(0, 20)}...`);

    try {
      const dataBuffer = this.stringToUint8Array(data);
      const hashBuffer = await this.computeSHA256(dataBuffer);
      const hashBase64 = this.uint8ArrayToBase64(hashBuffer);

      Logger.debug(LogTags.LIBSODIUM, `Hash: ${hashBase64.substring(0, 16)}...`);
      return hashBase64;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'Hash computation failed', error as Error);
      throw new Error(`Hash computation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 计算 SHA-512 哈希
   * @param data 要计算哈希的数据
   * @returns Base64 编码的哈希值
   */
  async hash512(data: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, 'Computing SHA-512 hash');

    try {
      const dataBuffer = this.stringToUint8Array(data);
      const hashBuffer = await this.computeSHA512(dataBuffer);
      const hashBase64 = this.uint8ArrayToBase64(hashBuffer);

      Logger.debug(LogTags.LIBSODIUM, `SHA-512 Hash: ${hashBase64.substring(0, 16)}...`);
      return hashBase64;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'SHA-512 hash computation failed', error as Error);
      throw new Error(`SHA-512 hash computation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 计算 HMAC
   * @param data 要计算 HMAC 的数据
   * @param key 密钥
   * @returns Base64 编码的 HMAC 值
   */
  async hmac(data: string, key: string): Promise<string> {
    Logger.debug(LogTags.LIBSODIUM, 'Computing HMAC');

    try {
      const dataBuffer = this.stringToUint8Array(data);
      const keyBuffer = this.base64ToUint8Array(key);

      // 创建 HMAC 算法实例
      const hmacGenerator = cryptoFramework.createMac('HMACSHA256');
      await hmacGenerator.init({ data: keyBuffer });

      // 生成 HMAC
      const hmacBlob = await hmacGenerator.doFinal({ data: dataBuffer });
      const hmacBase64 = this.uint8ArrayToBase64(new Uint8Array(hmacBlob.data));

      Logger.debug(LogTags.LIBSODIUM, `HMAC: ${hmacBase64.substring(0, 16)}...`);
      return hmacBase64;
    } catch (error) {
      Logger.error(LogTags.LIBSODIUM, 'HMAC computation failed', error as Error);
      throw new Error(`HMAC computation failed: ${(error as Error).message}`);
    }
  }

  // ========== 工具方法 ==========

  /**
   * 测试通道是否可用
   * @returns 始终返回 true
   */
  async ping(): Promise<boolean> {
    return true;
  }

  /**
   * AES-GCM 加密
   * @param plaintext 明文
   * @param key 密钥
   * @param nonce Nonce
   * @returns 加密结果 (包含 auth tag)
   */
  private async encryptAESGCM(
    plaintext: Uint8Array,
    key: Uint8Array,
    nonce: Uint8Array
  ): Promise<Uint8Array> {
    // 创建 AES-GCM 加密器
    const cipher = cryptoFramework.createCipher('AES256_GCM_NOPADDING');

    // 创建对称密钥
    const keyBlob: cryptoFramework.DataBlob = { data: key };
    const symKey = await cryptoFramework.createSymKeyGenerator('AES256').convertKey(keyBlob, null, null, null);

    // 初始化加密器
    const initParams: cryptoFramework.GcmParamsSpec = {
      nonce: nonce,
      aad: new Uint8Array(0),
      authTag: new Uint8Array(0)
    };
    await cipher.init(cryptoFramework.EncryptMode.ENCRYPT_MODE, symKey, initParams);

    // 加密数据
    const cipherBlob = await cipher.doFinal({ data: plaintext });

    // 获取 auth tag 并组合
    const ciphertext = new Uint8Array(cipherBlob.data);
    const authTag = await cipher.getAuthTag();

    return this.concatUint8Arrays(ciphertext, new Uint8Array(authTag));
  }

  /**
   * AES-GCM 解密
   * @param ciphertextWithTag 密文 (包含 auth tag)
   * @param key 密钥
   * @param nonce Nonce
   * @returns 明文
   */
  private async decryptAESGCM(
    ciphertextWithTag: Uint8Array,
    key: Uint8Array,
    nonce: Uint8Array
  ): Promise<Uint8Array> {
    // 分离密文和 auth tag
    const ciphertext = ciphertextWithTag.slice(0, -this.AES_TAG_SIZE);
    const authTag = ciphertextWithTag.slice(-this.AES_TAG_SIZE);

    // 创建 AES-GCM 解密器
    const cipher = cryptoFramework.createCipher('AES256_GCM_NOPADDING');

    // 创建对称密钥
    const keyBlob: cryptoFramework.DataBlob = { data: key };
    const symKey = await cryptoFramework.createSymKeyGenerator('AES256').convertKey(keyBlob, null, null, null);

    // 初始化解密器
    const initParams: cryptoFramework.GcmParamsSpec = {
      nonce: nonce,
      aad: new Uint8Array(0),
      authTag: authTag
    };
    await cipher.init(cryptoFramework.DecryptMode.DECRYPT_MODE, symKey, initParams);

    // 解密数据
    const cipherBlob = await cipher.doFinal({ data: ciphertext });

    return new Uint8Array(cipherBlob.data);
  }

  /**
   * 计算 SHA-256 哈希
   * @param data 输入数据
   * @returns 哈希值 (32 bytes)
   */
  private async computeSHA256(data: Uint8Array): Promise<Uint8Array> {
    const md = cryptoFramework.createMd('SHA256');
    await md.update({ data: data });
    const mdBlob = await md.digest();

    return new Uint8Array(mdBlob.data);
  }

  /**
   * 计算 SHA-512 哈希
   * @param data 输入数据
   * @returns 哈希值 (64 bytes)
   */
  private async computeSHA512(data: Uint8Array): Promise<Uint8Array> {
    const md = cryptoFramework.createMd('SHA512');
    await md.update({ data: data });
    const mdBlob = await md.digest();

    return new Uint8Array(mdBlob.data);
  }

  /**
   * 安全比较两个值（防止时序攻击）
   * @param a 值 A
   * @param b 值 B
   * @returns 是否相等
   */
  private constantTimeCompare(a: Uint8Array, b: Uint8Array): boolean {
    if (a.length !== b.length) {
      return false;
    }

    let result = 0;
    for (let i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result === 0;
  }

  /**
   * 合并多个 Uint8Array
   */
  private concatUint8Arrays(...arrays: Uint8Array[]): Uint8Array {
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
   * Uint8Array 转 Base64 字符串
   */
  private uint8ArrayToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < uint8Array.length; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * Base64 字符串转 Uint8Array
   */
  private base64ToUint8Array(base64: string): Uint8Array {
    const binary = atob(base64);
    const length = binary.length;
    const buffer = new ArrayBuffer(length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < length; i++) {
      uint8Array[i] = binary.charCodeAt(i);
    }
    return uint8Array;
  }

  /**
   * 字符串转 Uint8Array (UTF-8 编码)
   */
  private stringToUint8Array(str: string): Uint8Array {
    const encoder = new TextEncoder();
    return new Uint8Array(encoder.encodeInto(str).buffer || new ArrayBuffer(0));
  }

  /**
   * Uint8Array 转字符串 (UTF-8 解码)
   */
  private uint8ArrayToString(uint8Array: Uint8Array): string {
    const decoder = new TextDecoder();
    return decoder.decode(uint8Array);
  }

  /**
   * 清理资源
   */
  dispose(): void {
    Logger.debug(LogTags.LIBSODIUM, 'Disposing Libsodium Plugin');
  }
}

/**
 * Libsodium 管理器（单例）
 */
class LibsodiumManager {
  private static instance: LibsodiumPlugin;

  static getInstance(): LibsodiumPlugin {
    if (!LibsodiumManager.instance) {
      LibsodiumManager.instance = new LibsodiumPlugin();
    }
    return LibsodiumManager.instance;
  }
}

/**
 * 导出单例实例
 */
export const libsodiumPlugin = LibsodiumManager.getInstance();
