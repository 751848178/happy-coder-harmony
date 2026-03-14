import 'package:flutter/services.dart';

import '../../shared/utils/extensions.dart';
import 'harmony_platform.dart';

class HarmonyChannelInvoker {
  HarmonyChannelInvoker({
    required MethodChannel channel,
    required this.feature,
  }) : _channel = channel;

  final MethodChannel _channel;
  final String feature;

  Future<T?> invoke<T>(
    String method, {
    Map<String, Object?>? arguments,
    Duration? timeout,
  }) async {
    if (!HarmonyPlatform.isHarmonyOS) {
      return null;
    }

    try {
      final operation = _channel.invokeMethod<T>(method, arguments);
      if (timeout != null) {
        return await operation.timeout(timeout);
      }
      return await operation;
    } on MissingPluginException catch (error) {
      Logger.warning('[$feature] $method unavailable: $error');
    } on PlatformException catch (error) {
      final message = error.message ?? error.code;
      Logger.error('[$feature] $method failed: $message');
    } catch (error) {
      Logger.error('[$feature] $method failed: $error');
    }

    return null;
  }

  Future<bool> ping() async {
    return (await invoke<bool>('ping')) ?? false;
  }
}

abstract class HarmonyBridgeFeature {
  HarmonyBridgeFeature(String channelName, String feature)
      : invoker = HarmonyChannelInvoker(
          channel: MethodChannel(channelName),
          feature: feature,
        );

  final HarmonyChannelInvoker invoker;

  Future<bool> ping() => invoker.ping();
}

Map<String, dynamic>? toStringDynamicMap(Map<dynamic, dynamic>? value) {
  if (value == null) {
    return null;
  }

  return value.map(
    (key, item) => MapEntry(key.toString(), item),
  );
}

Map<String, String>? toStringMap(Map<dynamic, dynamic>? value) {
  final casted = toStringDynamicMap(value);
  if (casted == null) {
    return null;
  }

  return casted.map(
    (key, item) => MapEntry(key, item?.toString() ?? ''),
  );
}
