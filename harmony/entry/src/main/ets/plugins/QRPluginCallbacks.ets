import { QRPluginSupport } from './QRPluginSupport';

export class QRPluginCallbacks extends QRPluginSupport {
  protected notifyScanSuccess(result: QRScanResult): void {
    if (this.eventCallbacks.onScanSuccess) {
      this.eventCallbacks.onScanSuccess(result);
    }
  }

  /**
   * 通知扫描错误
   */
  protected notifyScanError(error: string): void {
    if (this.eventCallbacks.onScanError) {
      this.eventCallbacks.onScanError(error);
    }
  }

  /**
   * 通知相机已启动
   */
  protected notifyCameraStarted(): void {
    if (this.eventCallbacks.onCameraStarted) {
      this.eventCallbacks.onCameraStarted();
    }
  }

  /**
   * 通知相机已停止
   */
  protected notifyCameraStopped(): void {
    if (this.eventCallbacks.onCameraStopped) {
      this.eventCallbacks.onCameraStopped();
    }
  }

  /**
   * 通知闪光灯状态变化
   */
  protected notifyFlashChanged(enabled: boolean): void {
    if (this.eventCallbacks.onFlashChanged) {
      this.eventCallbacks.onFlashChanged(enabled);
    }
  }

  /**
   * 清理资源
   */
}
