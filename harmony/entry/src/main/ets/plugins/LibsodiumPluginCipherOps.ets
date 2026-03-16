import { Logger, LogTags } from '../utils/Logger';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { LibsodiumPluginKeyOps } from './LibsodiumPluginKeyOps';

export class LibsodiumPluginCipherOps extends LibsodiumPluginKeyOps {
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
}
