import { Logger, LogTags } from '../utils/Logger';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { KeyPair } from './LibsodiumPluginModels';
import { LibsodiumPluginBase } from './LibsodiumPluginBase';

export class LibsodiumPluginKeyOps extends LibsodiumPluginBase {
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
