import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  NewWantListener
} from '@ohos/flutter_ohos';

const TAG = 'HappyLinkingPlugin';
const CHANNEL_NAME = 'happy.linking';

export default class HappyLinkingPlugin implements
  FlutterPlugin,
  AbilityAware,
  NewWantListener,
  MethodCallHandler {
  private channel: MethodChannel | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private pendingLink: string | null = null;

  constructor(initialWant?: Want) {
    if (initialWant) {
      this.setLaunchWant(initialWant);
    }
  }

  getUniqueClassName(): string {
    return 'HappyLinkingPlugin';
  }

  setLaunchWant(want: Want): void {
    this.cacheWantLink(want);
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
    this.abilityBinding = binding;
    this.abilityBinding.addOnNewWantListener(this);
  }

  onDetachedFromAbility(): void {
    this.abilityBinding?.removeOnNewWantListener(this);
    this.abilityBinding = null;
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    this.cacheWantLink(want);
    Log.i(TAG, `Received new want for happy link, reason=${launchParams.launchReason}`);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'takePendingLink':
        result.success(this.takePendingLink());
        return;
      case 'peekPendingLink':
        result.success(this.pendingLink);
        return;
      default:
        result.notImplemented();
        return;
    }
  }

  private takePendingLink(): string | null {
    const nextLink = this.pendingLink;
    this.pendingLink = null;
    return nextLink;
  }

  private cacheWantLink(want: Want): void {
    const link = this.extractLink(want);
    if (link == null || link.length === 0) {
      return;
    }
    this.pendingLink = link;
    Log.i(TAG, `Cached happy link: ${link}`);
  }

  private extractLink(want: Want): string | null {
    const directUri = this.normalizeLink(want.uri);
    if (directUri != null) {
      return directUri;
    }

    if (want.parameters == null) {
      return null;
    }

    const candidates = [
      want.parameters['uri'],
      want.parameters['url'],
      want.parameters['link'],
      want.parameters['deepLink'],
      want.parameters['targetUrl']
    ];

    for (const value of candidates) {
      const link = this.normalizeLink(value);
      if (link != null) {
        return link;
      }
    }

    return null;
  }

  private normalizeLink(value: Object | string | null | undefined): string | null {
    if (typeof value !== 'string') {
      return null;
    }

    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return null;
    }

    if (!trimmed.startsWith('happy://')) {
      return null;
    }

    return trimmed;
  }
}
