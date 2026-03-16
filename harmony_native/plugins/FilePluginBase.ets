import { Logger, LogTags } from '../utils/Logger';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { FileSelectConfig, ImageSelectConfig, MimeTypes } from './FilePluginModels';

export class FilePluginBase {
  protected abilityContext: common.Context | null = null;
  protected defaultSelectConfig: FileSelectConfig = {
    mimeTypes: [MimeTypes.ALL],
    multiple: false
  };
  protected defaultImageConfig: ImageSelectConfig = {
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
  protected getFileNameFromUri(uri: string): string {
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
  protected getMimeTypeFromUri(uri: string): string {
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
  protected mimeTypesToSuffixFilters(mimeTypes: string[]): picker.DocumentViewPicker.FileSuffixFilter[] {
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
  protected mimeTypeToSuffixes(mimeType: string): string[] {
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
  protected async compressImage(uri: string, config: ImageSelectConfig): Promise<string> {
    // 简化实现：直接返回原图
    // 实际实现需要：
    // 1. 使用 ImageSource 解码图片
    // 2. 使用 ImagePacker 重新编码，设置质量和尺寸
    // 3. 保存到新文件

    return uri;
  }
}
