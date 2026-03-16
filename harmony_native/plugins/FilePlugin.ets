import { FilePluginContent } from './FilePluginContent';

export class FilePlugin extends FilePluginContent {}

class FileManager {
  private static instance: FilePlugin;

  static getInstance(): FilePlugin {
    if (!FileManager.instance) {
      FileManager.instance = new FilePlugin();
    }
    return FileManager.instance;
  }
}

export const filePlugin = FileManager.getInstance();
