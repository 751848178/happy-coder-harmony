// File Plugin
//
// 文件操作插件
//
// 功能：
// - 选择文件
// - 选择图片
// - 获取文件信息
// - 读取文件内容
// - 文件类型过滤

import { Logger, LogTags } from '../utils/Logger';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

/**
 * 文件信息
 */
export interface FileInfo {
  uri: string;               // 文件 URI
  path: string;              // 文件路径
  name: string;              // 文件名
  size: number;              // 文件大小 (bytes)
  mimeType: string;          // MIME 类型
  lastModified: number;      // 最后修改时间戳
  displayName?: string;      // 显示名称
}

/**
 * 文件选择配置
 */
export interface FileSelectConfig {
  mimeTypes: string[];       // 允许的 MIME 类型
  multiple: boolean;         // 是否允许多选
  maxFiles?: number;         // 最大文件数
  maxSize?: number;          // 最大文件大小 (bytes)
  startDir?: string;         // 起始目录
}

/**
 * 图片选择配置
 */
export interface ImageSelectConfig {
  maxWidth?: number;         // 最大宽度
  maxHeight?: number;        // 最大高度
  quality?: number;          // 质量 (0-1)
  enableEdit?: boolean;      // 允许编辑
  maxSelectNumber?: number;  // 最大选择数量
}

/**
 * 文件选择结果
 */
export interface FileSelectResult {
  files: FileInfo[];         // 选中的文件列表
  cancelled: boolean;        // 是否取消选择
}

/**
 * 文件保存选项
 */
export interface FileSaveOptions {
  fileName?: string;         // 文件名
  mimeType?: string;         // MIME 类型
  overwrite?: boolean;       // 是否覆盖
}

/**
 * 目录信息
 */
export interface DirectoryInfo {
  uri: string;               // 目录 URI
  name: string;              // 目录名
  path: string;              // 目录路径
  fileCount: number;         // 文件数量
  totalSize: number;         // 总大小
}

/**
 * 常用 MIME 类型
 */
export const MimeTypes = {
  // 图片
  IMAGE_JPEG: 'image/jpeg',
  IMAGE_PNG: 'image/png',
  IMAGE_GIF: 'image/gif',
  IMAGE_WEBP: 'image/webp',
  IMAGE_SVG: 'image/svg+xml',
  IMAGE_BMP: 'image/bmp',
  IMAGE_ALL: 'image/*',

  // 文档
  PDF: 'application/pdf',
  DOC: 'application/msword',
  DOCX: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  XLS: 'application/vnd.ms-excel',
  XLSX: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  PPT: 'application/vnd.ms-powerpoint',
  PPTX: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  TXT: 'text/plain',

  // 文本
  TEXT: 'text/plain',
  JSON: 'application/json',
  XML: 'text/xml',
  HTML: 'text/html',
  CSS: 'text/css',
  JS: 'text/javascript',

  // 压缩
  ZIP: 'application/zip',
  RAR: 'application/x-rar-compressed',
  TAR: 'application/x-tar',
  GZ: 'application/gzip',
  '7Z': 'application/x-7z-compressed',

  // 音频
  AUDIO_MP3: 'audio/mpeg',
  AUDIO_WAV: 'audio/wav',
  AUDIO_AAC: 'audio/aac',
  AUDIO_FLAC: 'audio/flac',
  AUDIO_M4A: 'audio/mp4',
  AUDIO_ALL: 'audio/*',

  // 视频
  VIDEO_MP4: 'video/mp4',
  VIDEO_MOV: 'video/quicktime',
  VIDEO_AVI: 'video/x-msvideo',
  VIDEO_MKV: 'video/x-matroska',
  VIDEO_WEBM: 'video/webm',
  VIDEO_ALL: 'video/*',

  // 代码
  CODE_TS: 'text/typescript',
  CODE_PY: 'text/x-python',
  CODE_JAVA: 'text/x-java',
  CODE_CPP: 'text/x-c++src',
  CODE_C: 'text/x-c',
  CODE_RS: 'text/x-rust',
  CODE_GO: 'text/x-go',
  CODE_PHP: 'text/x-php',

  // 其他
  OCTET_STREAM: 'application/octet-stream',
  ALL: '*/*'
} as const;

/**
 * File Plugin 类
 */
export class FilePlugin {
  private abilityContext: common.Context | null = null;
  private defaultSelectConfig: FileSelectConfig = {
    mimeTypes: [MimeTypes.ALL],
    multiple: false
  };
  private defaultImageConfig: ImageSelectConfig = {
    maxSelectNumber: 1,
    enableEdit: false,
    quality: 0.9
  };

  constructor() {
    Logger.debug(LogTags.FILE, 'File Plugin initialized');
  }

  /**
   * 设置 Ability Context
   */
  setContext(context: common.Context): void {
    this.abilityContext = context;
  }

  // ========== 文件选择 ==========

  /**
   * 选择文件
   * @param mimeTypes 允许的 MIME 类型列表
   * @param multiple 是否允许多选
   * @returns 文件 URI 列表
   */
  async selectFiles(mimeTypes: string[], multiple: boolean = false): Promise<string[] | null> {
    Logger.info(LogTags.FILE, `Selecting files: ${mimeTypes.join(', ')}, multiple=${multiple}`);

    if (!this.abilityContext) {
      Logger.error(LogTags.FILE, 'Ability context not set');
      return null;
    }

    try {
      const documentPicker = new picker.DocumentViewPicker(this.abilityContext);

      const options: picker.DocumentSelectOptions = {
        maxSelectNumber: multiple ? 100 : 1,
        fileSuffixFilters: this.mimeTypesToSuffixFilters(mimeTypes)
      };

      const documentSelectResult = await documentPicker.select(options);

      if (!documentSelectResult || documentSelectResult.length === 0) {
        Logger.debug(LogTags.FILE, 'File selection cancelled');
        return null;
      }

      const uris = documentSelectResult.map(result => result.uri);
      Logger.info(LogTags.FILE, `Selected ${uris.length} files`);

      return uris;
    } catch (error) {
      Logger.error(LogTags.FILE, 'File selection failed', error as Error);
      return null;
    }
  }

  /**
   * 选择单个文件
   * @param mimeType MIME 类型
   * @returns 文件 URI
   */
  async selectFile(mimeType: string = MimeTypes.ALL): Promise<string | null> {
    const result = await this.selectFiles([mimeType], false);
    return result && result.length > 0 ? result[0] : null;
  }

  /**
   * 保存文件
   * @param content 文件内容
   * @param options 保存选项
   * @returns 保存后的文件 URI
   */
  async saveFile(content: string, options?: FileSaveOptions): Promise<string | null> {
    Logger.info(LogTags.FILE, 'Saving file');

    if (!this.abilityContext) {
      Logger.error(LogTags.FILE, 'Ability context not set');
      return null;
    }

    try {
      const documentPicker = new picker.DocumentViewPicker(this.abilityContext);

      const saveOptions: picker.DocumentSaveOptions = {
        fileName: options?.fileName || 'untitled',
        newFileNames: [options?.fileName || 'untitled']
      };

      const saveResult = await documentPicker.save(saveOptions);

      if (!saveResult || saveResult.length === 0) {
        Logger.debug(LogTags.FILE, 'File save cancelled');
        return null;
      }

      const uri = saveResult[0].uri;

      // 写入文件内容
      const file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);

      Logger.info(LogTags.FILE, `File saved: ${uri}`);
      return uri;
    } catch (error) {
      Logger.error(LogTags.FILE, 'File save failed', error as Error);
      return null;
    }
  }

  // ========== 图片选择 ==========

  /**
   * 选择图片
   * @param options 图片选择配置
   * @returns 图片文件 URI
   */
  async selectImage(options?: Partial<ImageSelectConfig>): Promise<string | null> {
    Logger.info(LogTags.FILE, 'Selecting image');

    if (!this.abilityContext) {
      Logger.error(LogTags.FILE, 'Ability context not set');
      return null;
    }

    try {
      const config: ImageSelectConfig = { ...this.defaultImageConfig, ...options };

      const photoPicker = new picker.PhotoViewPicker();

      const photoSelectOptions: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: config.maxSelectNumber || 1,
        isEditSupported: config.enableEdit || false
      };

      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (!photoSelectResult || photoSelectResult.photoUris.length === 0) {
        Logger.debug(LogTags.FILE, 'Image selection cancelled');
        return null;
      }

      const imageUri = photoSelectResult.photoUris[0];
      Logger.info(LogTags.FILE, `Selected image: ${imageUri}`);

      // 可选：压缩图片
      if (config.maxWidth || config.maxHeight || (config.quality && config.quality < 1)) {
        return await this.compressImage(imageUri, config);
      }

      return imageUri;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Image selection failed', error as Error);
      return null;
    }
  }

  /**
   * 选择多张图片
   * @param maxCount 最大数量
   * @param options 选择配置
   * @returns 图片文件 URI 列表
   */
  async selectImages(maxCount: number = 9, options?: Partial<ImageSelectConfig>): Promise<string[] | null> {
    Logger.info(LogTags.FILE, `Selecting up to ${maxCount} images`);

    if (!this.abilityContext) {
      Logger.error(LogTags.FILE, 'Ability context not set');
      return null;
    }

    try {
      const config: ImageSelectConfig = { ...this.defaultImageConfig, ...options, maxSelectNumber: maxCount };

      const photoPicker = new picker.PhotoViewPicker();

      const photoSelectOptions: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: config.maxSelectNumber || maxCount,
        isEditSupported: config.enableEdit || false
      };

      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (!photoSelectResult || photoSelectResult.photoUris.length === 0) {
        Logger.debug(LogTags.FILE, 'Image selection cancelled');
        return null;
      }

      const uris = photoSelectResult.photoUris;
      Logger.info(LogTags.FILE, `Selected ${uris.length} images`);

      return uris;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Image selection failed', error as Error);
      return null;
    }
  }

  /**
   * 选择视频
   * @param maxCount 最大数量
   * @returns 视频文件 URI 列表
   */
  async selectVideos(maxCount: number = 1): Promise<string[] | null> {
    Logger.info(LogTags.FILE, `Selecting up to ${maxCount} videos`);

    if (!this.abilityContext) {
      Logger.error(LogTags.FILE, 'Ability context not set');
      return null;
    }

    try {
      const photoPicker = new picker.PhotoViewPicker();

      const photoSelectOptions: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.VIDEO_TYPE,
        maxSelectNumber: maxCount
      };

      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (!photoSelectResult || photoSelectResult.photoUris.length === 0) {
        Logger.debug(LogTags.FILE, 'Video selection cancelled');
        return null;
      }

      const uris = photoSelectResult.photoUris;
      Logger.info(LogTags.FILE, `Selected ${uris.length} videos`);

      return uris;
    } catch (error) {
      Logger.error(LogTags.FILE, 'Video selection failed', error as Error);
      return null;
    }
  }

  // ========== 文件信息 ==========

  /**
   * 获取文件信息
   * @param uri 文件 URI
   * @returns 文件信息
   */
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

  // ========== 文件内容 ==========

  /**
   * 读取文件内容（文本）
   * @param uri 文件 URI
   * @returns 文件内容
   */
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

  // ========== 工具方法 ==========

  /**
   * 测试通道是否可用
   */
  async ping(): Promise<boolean> {
    return true;
  }

  /**
   * 从 URI 获取文件名
   */
  private getFileNameFromUri(uri: string): string {
    // 处理 file:// URI 格式
    if (uri.startsWith('file://')) {
      uri = uri.substring(7);
    }

    const parts = uri.split('/');
    return parts[parts.length - 1] || uri;
  }

  /**
   * 从 URI 获取 MIME 类型
   */
  private getMimeTypeFromUri(uri: string): string {
    const ext = uri.split('.').pop()?.toLowerCase() || '';

    const mimeMap: Record<string, string> = {
      // 图片
      'jpg': MimeTypes.IMAGE_JPEG,
      'jpeg': MimeTypes.IMAGE_JPEG,
      'png': MimeTypes.IMAGE_PNG,
      'gif': MimeTypes.IMAGE_GIF,
      'webp': MimeTypes.IMAGE_WEBP,
      'bmp': MimeTypes.IMAGE_BMP,
      'svg': MimeTypes.IMAGE_SVG,

      // 文档
      'pdf': MimeTypes.PDF,
      'doc': MimeTypes.DOC,
      'docx': MimeTypes.DOCX,
      'xls': MimeTypes.XLS,
      'xlsx': MimeTypes.XLSX,
      'ppt': MimeTypes.PPT,
      'pptx': MimeTypes.PPTX,
      'txt': MimeTypes.TXT,

      // 文本
      'json': MimeTypes.JSON,
      'xml': MimeTypes.XML,
      'html': MimeTypes.HTML,
      'css': MimeTypes.CSS,
      'js': MimeTypes.JS,

      // 音频
      'mp3': MimeTypes.AUDIO_MP3,
      'wav': MimeTypes.AUDIO_WAV,
      'aac': MimeTypes.AUDIO_AAC,
      'flac': MimeTypes.AUDIO_FLAC,
      'm4a': MimeTypes.AUDIO_M4A,

      // 视频
      'mp4': MimeTypes.VIDEO_MP4,
      'mov': MimeTypes.VIDEO_MOV,
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': MimeTypes.VIDEO_WEBM,

      // 压缩
      'zip': MimeTypes.ZIP,
      'rar': MimeTypes.RAR,
      'tar': MimeTypes.TAR,
      'gz': MimeTypes.GZ,
      '7z': MimeTypes['7Z'],

      // 代码
      'ts': MimeTypes.CODE_TS,
      'tsx': MimeTypes.CODE_TS,
      'py': MimeTypes.CODE_PY,
      'java': MimeTypes.CODE_JAVA,
      'cpp': MimeTypes.CODE_CPP,
      'c': MimeTypes.CODE_C,
      'rs': MimeTypes.CODE_RS,
      'go': MimeTypes.CODE_GO,
      'php': MimeTypes.CODE_PHP
    };

    return mimeMap[ext] || MimeTypes.OCTET_STREAM;
  }

  /**
   * 将 MIME 类型转换为文件后缀过滤器
   */
  private mimeTypesToSuffixFilters(mimeTypes: string[]): picker.DocumentViewPicker.FileSuffixFilter[] {
    const filters: picker.DocumentViewPicker.FileSuffixFilter[] = [];

    for (const mimeType of mimeTypes) {
      const suffixes = this.mimeTypeToSuffixes(mimeType);
      if (suffixes.length > 0) {
        filters.push({
          suffixes: suffixes
        });
      }
    }

    return filters;
  }

  /**
   * 将 MIME 类型转换为文件后缀
   */
  private mimeTypeToSuffixes(mimeType: string): string[] {
    if (mimeType === MimeTypes.ALL || mimeType === '*/*') {
      return ['*'];
    }

    const mimeMap: Record<string, string[]> = {
      [MimeTypes.IMAGE_ALL]: ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'],
      [MimeTypes.IMAGE_JPEG]: ['.jpg', '.jpeg'],
      [MimeTypes.IMAGE_PNG]: ['.png'],
      [MimeTypes.IMAGE_GIF]: ['.gif'],
      [MimeTypes.IMAGE_WEBP]: ['.webp'],
      [MimeTypes.IMAGE_BMP]: ['.bmp'],
      [MimeTypes.IMAGE_SVG]: ['.svg'],
      [MimeTypes.PDF]: ['.pdf'],
      [MimeTypes.DOC]: ['.doc'],
      [MimeTypes.DOCX]: ['.docx'],
      [MimeTypes.XLS]: ['.xls'],
      [MimeTypes.XLSX]: ['.xlsx'],
      [MimeTypes.PPT]: ['.ppt'],
      [MimeTypes.PPTX]: ['.pptx'],
      [MimeTypes.TXT]: ['.txt'],
      [MimeTypes.TEXT]: ['.txt'],
      [MimeTypes.JSON]: ['.json'],
      [MimeTypes.XML]: ['.xml'],
      [MimeTypes.HTML]: ['.html', '.htm'],
      [MimeTypes.CSS]: ['.css'],
      [MimeTypes.JS]: ['.js'],
      [MimeTypes.ZIP]: ['.zip'],
      [MimeTypes.RAR]: ['.rar'],
      [MimeTypes.TAR]: ['.tar'],
      [MimeTypes.GZ]: ['.gz'],
      [MimeTypes.AUDIO_ALL]: ['.mp3', '.wav', '.aac', '.flac', '.m4a', '.ogg'],
      [MimeTypes.AUDIO_MP3]: ['.mp3'],
      [MimeTypes.AUDIO_WAV]: ['.wav'],
      [MimeTypes.AUDIO_AAC]: ['.aac'],
      [MimeTypes.AUDIO_FLAC]: ['.flac'],
      [MimeTypes.AUDIO_M4A]: ['.m4a'],
      [MimeTypes.VIDEO_ALL]: ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'],
      [MimeTypes.VIDEO_MP4]: ['.mp4'],
      [MimeTypes.VIDEO_MOV]: ['.mov'],
      [MimeTypes.VIDEO_WEBM]: ['.webm'],
      [MimeTypes.CODE_TS]: ['.ts', '.tsx'],
      [MimeTypes.CODE_PY]: ['.py'],
      [MimeTypes.CODE_JAVA]: ['.java'],
      [MimeTypes.CODE_CPP]: ['.cpp', '.cc', '.cxx'],
      [MimeTypes.CODE_C]: ['.c'],
      [MimeTypes.CODE_RS]: ['.rs'],
      [MimeTypes.CODE_GO]: ['.go'],
      [MimeTypes.CODE_PHP]: ['.php']
    };

    return mimeMap[mimeType] || [];
  }

  /**
   * 压缩图片（简化实现）
   * 注意：实际实现需要使用 @ohos.multimedia.image 进行图片压缩
   */
  private async compressImage(uri: string, config: ImageSelectConfig): Promise<string> {
    // 简化实现：直接返回原图
    // 实际实现需要：
    // 1. 使用 ImageSource 解码图片
    // 2. 使用 ImagePacker 重新编码，设置质量和尺寸
    // 3. 保存到新文件

    return uri;
  }
}

/**
 * File 管理器（单例）
 */
class FileManager {
  private static instance: FilePlugin;

  static getInstance(): FilePlugin {
    if (!FileManager.instance) {
      FileManager.instance = new FilePlugin();
    }
    return FileManager.instance;
  }
}

/**
 * 导出单例实例
 */
export const filePlugin = FileManager.getInstance();
