import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import window from '@ohos.window';

const TAG = 'HappyScreenAwakePlugin';
const CHANNEL_NAME = 'happy.screen_awake';

export default class HappyScreenAwakePlugin implements
  FlutterPlugin,
  AbilityAware,
  MethodCallHandler {
  private channel: MethodChannel | null = null;
  private abilityContext: common.UIAbilityContext | null = null;
  private keepScreenOn = false;

  getUniqueClassName(): string {
    return 'HappyScreenAwakePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityContext = binding.getAbility().context as common.UIAbilityContext;
  }

  onDetachedFromAbility(): void {
    this.abilityContext = null;
    this.keepScreenOn = false;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'ping':
        result.success(true);
        return;
      case 'setKeepScreenOn':
        void this.handleSetKeepScreenOn(call, result);
        return;
      case 'isKeepScreenOn':
        result.success(this.keepScreenOn);
        return;
      default:
        result.notImplemented();
        return;
    }
  }

  private async handleSetKeepScreenOn(
    call: MethodCall,
    result: MethodResult,
  ): Promise<void> {
    if (this.abilityContext == null) {
      result.error('no-ability', 'Current ability context is unavailable', null);
      return;
    }

    const enabled = this.readEnabled(call.args);
    if (enabled == null) {
      result.error('invalid-args', 'Missing bool argument: enabled', null);
      return;
    }

    try {
      const appWindow = await window.getLastWindow(this.abilityContext);
      await appWindow.setWindowKeepScreenOn(enabled);
      this.keepScreenOn = enabled;
      result.success(true);
    } catch (error) {
      Log.e(TAG, `Failed to update keep-screen-on: ${JSON.stringify(error)}`);
      result.error(
        'keep-screen-on-failed',
        `Failed to update keep-screen-on: ${JSON.stringify(error)}`,
        null,
      );
    }
  }

  private readEnabled(value: Object | null): boolean | null {
    if (value == null || !(value instanceof Map)) {
      return null;
    }
    const args = value as Map<string, Object>;
    if (!args.has('enabled')) {
      return null;
    }
    const raw = args.get('enabled');
    return typeof raw === 'boolean' ? raw : null;
  }
}
