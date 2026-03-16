import { Logger, LogTags } from '../utils/Logger';
import fs from '@ohos.file.fs';
import { FilePluginMetadata } from './FilePluginMetadata';

export class FilePluginContent extends FilePluginMetadata {
  async readFile(uri: string): Promise<string | null> {
    Logger.debug(LogTags.FILE, `Reading file: ${uri}`);

    try {
      const content = fs.readTextSync(uri);
      Logger.debug(LogTags.FILE, `File read successfully, size: ${content.length}`);
      return content;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to read file', error as Error);
      return null;
    }
  }

  /**
   * 读取文件内容（二进制）
   * @param uri 文件 URI
   * @param offset 偏移量
   * @param length 读取长度
   * @returns 文件内容（ArrayBuffer）
   */
  async readFileBinary(uri: string, offset?: number, length?: number): Promise<ArrayBuffer | null> {
    Logger.debug(LogTags.FILE, `Reading binary file: ${uri}`);

    try {
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const readLength = length || (file.stat?.size || fs.statSync(uri).size);

      const buffer = new ArrayBuffer(readLength);
      const readLen = fs.readSync(file.fd, buffer, { offset: offset || 0 });

      fs.closeSync(file);

      if (readLen < buffer.byteLength) {
        // 返回实际读取的数据
        return buffer.slice(0, readLen);
      }

      Logger.debug(LogTags.FILE, `Binary file read successfully, size: ${readLen}`);
      return buffer;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to read binary file', error as Error);
      return null;
    }
  }

  /**
   * 写入文件
   * @param uri 文件 URI
   * @param content 文件内容
   * @param mode 写入模式
   * @returns 写入的字节数
   */
  async writeFile(uri: string, content: string, mode: fs.OpenMode = fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE): Promise<number | null> {
    Logger.debug(LogTags.FILE, `Writing file: ${uri}`);

    try {
      const file = fs.openSync(uri, mode);
      const written = fs.writeSync(file.fd, content);
      fs.closeSync(file);

      Logger.debug(LogTags.FILE, `File written successfully, bytes: ${written}`);
      return written;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to write file', error as Error);
      return null;
    }
  }

  /**
   * 写入二进制文件
   * @param uri 文件 URI
   * @param data 二进制数据
   * @param mode 写入模式
   * @returns 写入的字节数
   */
  async writeFileBinary(uri: string, data: ArrayBuffer, mode: fs.OpenMode = fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE): Promise<number | null> {
    Logger.debug(LogTags.FILE, `Writing binary file: ${uri}`);

    try {
      const file = fs.openSync(uri, mode);
      const written = fs.writeSync(file.fd, data);
      fs.closeSync(file);

      Logger.debug(LogTags.FILE, `Binary file written successfully, bytes: ${written}`);
      return written;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to write binary file', error as Error);
      return null;
    }
  }

  /**
   * 复制文件
   * @param sourceUri 源文件 URI
   * @param targetUri 目标文件 URI
   * @returns 是否成功
   */
  async copyFile(sourceUri: string, targetUri: string): Promise<boolean> {
    Logger.debug(LogTags.FILE, `Copying file: ${sourceUri} -> ${targetUri}`);

    try {
      fs.copyFileSync(sourceUri, targetUri);
      Logger.debug(LogTags.FILE, 'File copied successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to copy file', error as Error);
      return false;
    }
  }

  /**
   * 移动文件
   * @param sourceUri 源文件 URI
   * @param targetUri 目标文件 URI
   * @returns 是否成功
   */
  async moveFile(sourceUri: string, targetUri: string): Promise<boolean> {
    Logger.debug(LogTags.FILE, `Moving file: ${sourceUri} -> ${targetUri}`);

    try {
      fs.moveFileSync(sourceUri, targetUri);
      Logger.debug(LogTags.FILE, 'File moved successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to move file', error as Error);
      return false;
    }
  }

  /**
   * 删除文件
   * @param uri 文件 URI
   * @returns 是否成功
   */
  async deleteFile(uri: string): Promise<boolean> {
    Logger.debug(LogTags.FILE, `Deleting file: ${uri}`);

    try {
      fs.unlinkSync(uri);
      Logger.debug(LogTags.FILE, 'File deleted successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to delete file', error as Error);
      return false;
    }
  }

  /**
   * 判断文件是否存在
   * @param uri 文件 URI
   * @returns 是否存在
   */
  async fileExists(uri: string): Promise<boolean> {
    try {
      fs.accessSync(uri);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 创建目录
   * @param uri 目录 URI
   * @param recursive 是否递归创建
   * @returns 是否成功
   */
  async createDirectory(uri: string, recursive: boolean = true): Promise<boolean> {
    Logger.debug(LogTags.FILE, `Creating directory: ${uri}`);

    try {
      if (recursive) {
        fs.mkdirSync(uri, true);
      } else {
        fs.mkdirSync(uri, false);
      }
      Logger.debug(LogTags.FILE, 'Directory created successfully');
      return true;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to create directory', error as Error);
      return false;
    }
  }

  async ping(): Promise<boolean> {
    return true;
  }
}
