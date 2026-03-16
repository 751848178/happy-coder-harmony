import { Logger, LogTags } from '../utils/Logger';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { LibsodiumPluginCipherOps } from './LibsodiumPluginCipherOps';

export class LibsodiumPluginHashOps extends LibsodiumPluginCipherOps {
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
}
