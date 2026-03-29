
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import HappyLinkingPlugin from '../plugins/HappyLinkingPlugin';
import HappyQRCodePlugin from '../plugins/HappyQRCodePlugin';
import HappyScreenAwakePlugin from '../plugins/HappyScreenAwakePlugin';

export default class EntryAbility extends FlutterAbility {
  private happyLinkingPlugin = new HappyLinkingPlugin();
  private happyQRCodePlugin = new HappyQRCodePlugin();
  private happyScreenAwakePlugin = new HappyScreenAwakePlugin();

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    this.happyLinkingPlugin.setLaunchWant(this.getWant())
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(this.happyLinkingPlugin)
    flutterEngine.getPlugins()?.add(this.happyQRCodePlugin)
    flutterEngine.getPlugins()?.add(this.happyScreenAwakePlugin)
  }
}
