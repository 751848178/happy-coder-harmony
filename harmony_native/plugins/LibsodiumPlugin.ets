import { LibsodiumPluginHashOps } from './LibsodiumPluginHashOps';

export class LibsodiumPlugin extends LibsodiumPluginHashOps {}

class LibsodiumManager {
  private static instance: LibsodiumPlugin;

  static getInstance(): LibsodiumPlugin {
    if (!LibsodiumManager.instance) {
      LibsodiumManager.instance = new LibsodiumPlugin();
    }
    return LibsodiumManager.instance;
  }
}

export const libsodiumPlugin = LibsodiumManager.getInstance();
