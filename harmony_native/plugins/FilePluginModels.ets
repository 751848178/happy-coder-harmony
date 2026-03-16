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
