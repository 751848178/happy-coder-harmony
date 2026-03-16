import { Logger, LogTags } from '../utils/Logger';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { DirectoryInfo, FileInfo } from './FilePluginModels';
import { FilePluginMedia } from './FilePluginMedia';

export class FilePluginMetadata extends FilePluginMedia {
  async getFileInfo(uri: string): Promise<FileInfo | null> {
    Logger.debug(LogTags.FILE, `Getting file info for: ${uri}`);

    try {
      const stat = await fs.stat(uri);

      const info: FileInfo = {
        uri: uri,
        path: uri,
        name: this.getFileNameFromUri(uri),
        size: stat.size,
        mimeType: this.getMimeTypeFromUri(uri),
        lastModified: stat.mtime,
        displayName: this.getFileNameFromUri(uri)
      };

      Logger.debug(LogTags.FILE, `File info: ${JSON.stringify(info)}`);
      return info;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to get file info', error as Error);
      return null;
    }
  }

  /**
   * 批量获取文件信息
   * @param uris 文件 URI 列表
   * @returns 文件信息列表
   */
  async getMultipleFileInfo(uris: string[]): Promise<FileInfo[]> {
    Logger.debug(LogTags.FILE, `Getting info for ${uris.length} files`);

    const results = await Promise.all(
      uris.map(uri => this.getFileInfo(uri))
    );

    return results.filter((info): info is FileInfo => info !== null);
  }

  /**
   * 获取目录信息
   * @param uri 目录 URI
   * @returns 目录信息
   */
  async getDirectoryInfo(uri: string): Promise<DirectoryInfo | null> {
    Logger.debug(LogTags.FILE, `Getting directory info for: ${uri}`);

    try {
      const entries = await fs.listFile(uri);

      let totalSize = 0;
      const fileCount = entries.length;

      // 计算总大小
      for (const entry of entries) {
        try {
          const stat = await fs.stat(entry);
          if (!stat.isDirectory()) {
            totalSize += stat.size;
          }
        } catch (e) {
          // 忽略无法访问的文件
        }
      }

      const info: DirectoryInfo = {
        uri: uri,
        name: this.getFileNameFromUri(uri),
        path: uri,
        fileCount,
        totalSize
      };

      Logger.debug(LogTags.FILE, `Directory info: ${JSON.stringify(info)}`);
      return info;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Failed to get directory info', error as Error);
      return null;
    }
}
