import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/auth_models.dart' show Credentials;
import '../../../shared/utils/extensions.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/device_models.dart';

part 'device_repository_control.dart';
part 'device_repository_devices.dart';

class DeviceRepository {
  DeviceRepository._();

  static final DeviceRepository instance = DeviceRepository._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.serverUrl,
      connectTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': AppConfig.userAgent,
      },
    ),
  );

  Credentials? _credentials;

  Dio get _client {
    _dio.options.baseUrl = AppConfig.serverUrl;
    return _dio;
  }

  Future<void> initialize() async {
    _credentials = await AuthRepository.instance.getCredentials();
    Logger.info('Device repository initialized');
  }

  Future<void> _updateCredentials() async {
    _credentials = await AuthRepository.instance.getCredentials();
  }

  Options _getAuthOptions() {
    if (_credentials?.token != null) {
      return Options(
        headers: {
          ..._client.options.headers,
          'Authorization': 'Bearer ${_credentials!.token}',
        },
      );
    }
    return Options();
  }

  Future<bool> requestControl(String targetDeviceId) =>
      _requestDeviceControl(this, targetDeviceId);

  Future<void> releaseControl() => _releaseDeviceControl(this);

  Future<void> approveControlRequest(String requestId) =>
      _approveDeviceControlRequest(this, requestId);

  Future<void> rejectControlRequest(String requestId, {String? reason}) =>
      _rejectDeviceControlRequest(this, requestId, reason: reason);

  Future<void> sendControlPing() => _sendDeviceControlPing(this);

  Future<List<DeviceInfo>> getDevices() => _getRepositoryDevices(this);

  Future<DeviceInfo?> getCurrentDevice() => _getCurrentRepositoryDevice(this);

  Future<List<ControlRequest>> getControlRequests() =>
      _getRepositoryControlRequests(this);

  Stream<ControlRequest> listenToControlRequests() => Stream.empty();
}
