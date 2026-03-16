import { QRPluginPermissions } from './QRPluginPermissions';

export class QRPlugin extends QRPluginPermissions {
  dispose(): void {
    Logger.debug(LogTags.QR, 'Disposing QR Plugin');
    this.stopScanning();
    this.eventStream = [];
  }
}

/**
 * QR 管理器（单例）
 */
class QRManager {
}

class QRManager {
  private static instance: QRPlugin;

  static getInstance(): QRPlugin {
    if (!QRManager.instance) {
      QRManager.instance = new QRPlugin();
    }
    return QRManager.instance;
  }
}

export const qrPlugin = QRManager.getInstance();
export default QRPlugin;
