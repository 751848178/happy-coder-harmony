import { Logger, LogTags } from '../utils/Logger';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { ImageSelectConfig } from './FilePluginModels';
import { FilePluginSelection } from './FilePluginSelection';

export class FilePluginMedia extends FilePluginSelection {
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
