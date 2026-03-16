import { QRPluginPermissions } from './QRPluginPermissions';

export class QRPlugin extends QRPluginPermissions {}

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
