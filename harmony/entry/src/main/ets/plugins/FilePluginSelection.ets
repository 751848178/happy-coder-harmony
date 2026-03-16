import { Logger, LogTags } from '../utils/Logger';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { FileSaveOptions, MimeTypes } from './FilePluginModels';
import { FilePluginBase } from './FilePluginBase';

export class FilePluginSelection extends FilePluginBase {
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
}
