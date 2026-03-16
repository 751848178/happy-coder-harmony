import { Logger, LogTags } from '../utils/Logger';
import cryptoFramework from '@ohos.security.cryptoFramework';

export class LibsodiumPluginBase {
  protected readonly KEY_SIZE_256 = 32;     // 256 bits
  protected readonly KEY_SIZE_128 = 16;     // 128 bits
  protected readonly NONCE_SIZE = 12;       // 96 bits (GCM 标准)
  protected readonly AES_TAG_SIZE = 16;    // 128 bits

  constructor() {
    Logger.debug(LogTags.LIBSODIUM, 'Libsodium Plugin initialized');
  }
  protected async encryptAESGCM(
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
  protected async decryptAESGCM(
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
  protected async computeSHA256(data: Uint8Array): Promise<Uint8Array> {
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
  protected async computeSHA512(data: Uint8Array): Promise<Uint8Array> {
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
  protected constantTimeCompare(a: Uint8Array, b: Uint8Array): boolean {
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
  protected concatUint8Arrays(...arrays: Uint8Array[]): Uint8Array {
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
  protected uint8ArrayToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < uint8Array.length; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return btoa(binary);
  }

  /**
   * Base64 字符串转 Uint8Array
   */
  protected base64ToUint8Array(base64: string): Uint8Array {
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
  protected stringToUint8Array(str: string): Uint8Array {
    const encoder = new TextEncoder();
    return new Uint8Array(encoder.encodeInto(str).buffer || new ArrayBuffer(0));
  }

  /**
   * Uint8Array 转字符串 (UTF-8 解码)
   */
  protected uint8ArrayToString(uint8Array: Uint8Array): string {
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
