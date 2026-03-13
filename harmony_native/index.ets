/**
 * Happy Coder HarmonyOS Native Plugins
 */

export { default as DevicePlugin } from './plugins/DevicePlugin';
export { default as LiveKitPlugin } from './plugins/LiveKitPlugin';
export { default as LibsodiumPlugin } from './plugins/LibsodiumPlugin';
export { default as PushPlugin } from './plugins/PushPlugin';
export {
  default as QRPlugin,
  qrPlugin,
  QRErrorCorrectionLevel,
  QRScanEventType,
  ScanType,
} from './plugins/QRPlugin';
export { default as FilePlugin } from './plugins/FilePlugin';

export { default as Conversion } from './utils/Conversion';
export { default as Logger } from './utils/Logger';

export const HarmonyPlugins = {
  DevicePlugin: {
    channelName: 'happy.device',
    className: 'DevicePlugin',
  },
  LiveKitPlugin: {
    channelName: 'happy.livekit',
    className: 'LiveKitPlugin',
  },
  LibsodiumPlugin: {
    channelName: 'happy.libsodium',
    className: 'LibsodiumPlugin',
  },
  PushPlugin: {
    channelName: 'happy.push',
    className: 'PushPlugin',
  },
  QRPlugin: {
    channelName: 'happy.qrcode',
    className: 'QRPlugin',
  },
  FilePlugin: {
    channelName: 'happy.file',
    className: 'FilePlugin',
  },
};
