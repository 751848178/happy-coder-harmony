import UIAbility from '@ohos.ability.ability';
import window from '@ohos.window';
import { Logger, LogTags } from '../utils/Logger';
import common from '@ohos.app.ability.common';
import { liveKitPlugin, LiveKitConnectionState } from '../plugins/LiveKitPlugin';
import { libsodiumPlugin } from '../plugins/LibsodiumPlugin';
import { pushPlugin } from '../plugins/PushPlugin';
import { qrPlugin } from '../plugins/QRPlugin';
import { filePlugin } from '../plugins/FilePlugin';
import { devicePlugin } from '../plugins/DevicePlugin';

type MethodChannel = any;
type EventChannel = any;

import { EntryAbilityPushQr } from './EntryAbilityPushQr';

export class EntryAbilityFileChannel extends EntryAbilityPushQr {
  protected setupFileChannel(): void {
    // this.fileChannel = new MethodChannel('happy.file', flutterBridge);

    const handlers: Record<string, Function> = {
      'selectFiles': (args: Record<string, Object>) => {
        const mimeTypes = (args['mimeTypes'] as string[]) || [];
        const multiple = (args['multiple'] as boolean) || false;
        return filePlugin.selectFiles(mimeTypes, multiple);
      },
      'selectFile': (args: Record<string, Object>) => {
        const mimeType = args['mimeType'] as string;
        return filePlugin.selectFile(mimeType);
      },
      'selectImage': (args: Record<string, Object>) => {
        const options = args['options'] as any;
        return filePlugin.selectImage(options);
      },
      'selectImages': (args: Record<string, Object>) => {
        const maxCount = (args['maxCount'] as number) || 9;
        return filePlugin.selectImages(maxCount);
      },
      'selectVideos': (args: Record<string, Object>) => {
        const maxCount = (args['maxCount'] as number) || 1;
        return filePlugin.selectVideos(maxCount);
      },
      'saveFile': (args: Record<string, Object>) => {
        const content = args['content'] as string;
        const options = args['options'] as any;
        return filePlugin.saveFile(content, options);
      },
      'getInfo': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.getFileInfo(uri);
      },
      'getMultipleFileInfo': (args: Record<string, Object>) => {
        const uris = args['uris'] as string[];
        return filePlugin.getMultipleFileInfo(uris);
      },
      'getDirectoryInfo': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.getDirectoryInfo(uri);
      },
      'readFile': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.readFile(uri);
      },
      'readFileBinary': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const offset = args['offset'] as number;
        const length = args['length'] as number;
        return filePlugin.readFileBinary(uri, offset, length);
      },
      'writeFile': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const content = args['content'] as string;
        return filePlugin.writeFile(uri, content);
      },
      'writeFileBinary': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const data = args['data'] as ArrayBuffer;
        return filePlugin.writeFileBinary(uri, data);
      },
      'copyFile': (args: Record<string, Object>) => {
        const sourceUri = args['sourceUri'] as string;
        const targetUri = args['targetUri'] as string;
        return filePlugin.copyFile(sourceUri, targetUri);
      },
      'moveFile': (args: Record<string, Object>) => {
        const sourceUri = args['sourceUri'] as string;
        const targetUri = args['targetUri'] as string;
        return filePlugin.moveFile(sourceUri, targetUri);
      },
      'deleteFile': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.deleteFile(uri);
      },
      'fileExists': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        return filePlugin.fileExists(uri);
      },
      'createDirectory': (args: Record<string, Object>) => {
        const uri = args['uri'] as string;
        const recursive = (args['recursive'] as boolean) || true;
        return filePlugin.createDirectory(uri, recursive);
      },
      'ping': () => {
        return filePlugin.ping();
      }
    };

    // this.fileChannel.setMethodCallHandler(handlers);

    Logger.info(LogTags.FILE, 'File channel handlers registered');
  }

  // ========== Device 通道 ==========
}
