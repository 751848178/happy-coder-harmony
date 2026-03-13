
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import HappyLinkingPlugin from '../plugins/HappyLinkingPlugin';
import HappyQRCodePlugin from '../plugins/HappyQRCodePlugin';

export default class EntryAbility extends FlutterAbility {
  private happyLinkingPlugin = new HappyLinkingPlugin();
  private happyQRCodePlugin = new HappyQRCodePlugin();

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    this.happyLinkingPlugin.setLaunchWant(this.getWant())
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    flutterEngine.getPlugins()?.add(this.happyLinkingPlugin)
    flutterEngine.getPlugins()?.add(this.happyQRCodePlugin)
  }
}
