import 'channel_invoker.dart';
import 'channel_names.dart';

class FileBridgeService extends HarmonyBridgeFeature {
  FileBridgeService._() : super(HarmonyChannelNames.file, 'file');

  static final FileBridgeService instance = FileBridgeService._();

  Future<List<String>?> selectFiles(List<String> mimeTypes) async {
    final result = await invoker.invoke<List<dynamic>>(
      'selectFiles',
      arguments: {'mimeTypes': mimeTypes},
    );
    return result?.map((item) => item.toString()).toList();
  }

  Future<String?> selectImage() async {
    return invoker.invoke<String>('selectImage');
  }

  Future<Map<String, dynamic>?> getInfo(String path) async {
    final result = await invoker.invoke<Map<dynamic, dynamic>>(
      'getInfo',
      arguments: {'path': path},
    );
    return toStringDynamicMap(result);
  }
}
