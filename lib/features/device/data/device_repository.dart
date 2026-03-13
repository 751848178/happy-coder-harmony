import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/models/auth_models.dart' show Credentials;
import '../../auth/data/auth_repository.dart';
import '../domain/device_models.dart';

/// 设备数据仓库
///
/// 处理设备控制权的 API 调用
class DeviceRepository {
  DeviceRepository._();

  static final DeviceRepository instance = DeviceRepository._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.serverUrl,
    connectTimeout: Duration(milliseconds: AppConfig.socketTimeout),
    receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': AppConfig.userAgent,
    },
  ));

  /// 认证凭证缓存
  Credentials? _credentials;

  /// 初始化仓库
  Future<void> initialize() async {
    _credentials = await AuthRepository.instance.getCredentials();
    Logger.info('Device repository initialized');
  }

  /// 更新凭证
  Future<void> _updateCredentials() async {
    _credentials = await AuthRepository.instance.getCredentials();
  }

  /// 确保 API 调用有认证头
  Options _getAuthOptions() {
    if (_credentials?.token != null) {
      return Options(
        headers: {
          ..._dio.options.headers,
          'Authorization': 'Bearer ${_credentials!.token}',
        },
      );
    }
    return Options();
  }

  // ========== 控制权 API ==========

  /// 请求控制权
  Future<bool> requestControl(String targetDeviceId) async {
    try {
      await _updateCredentials();

      final response = await _dio.post(
        '/v1/device/control/request',
        options: _getAuthOptions(),
        data: {
          'targetDeviceId': targetDeviceId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('Control request sent');
        return true;
      } else {
        throw Exception('Failed to request control: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Request control failed: ${e.message}');
      rethrow;
    }
  }

  /// 释放控制权
  Future<void> releaseControl() async {
    try {
      await _updateCredentials();

      final response = await _dio.post(
        '/v1/device/control/release',
        options: _getAuthOptions(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to release control: ${response.statusCode}');
      }

      Logger.info('Control released');
    } catch (e) {
      Logger.error('Release control failed: $e');
      rethrow;
    }
  }

  /// 批准控制权请求
  Future<void> approveControlRequest(String requestId) async {
    try {
      await _updateCredentials();

      final response = await _dio.post(
        '/v1/device/control/$requestId/approve',
        options: _getAuthOptions(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to approve control: ${response.statusCode}');
      }

      Logger.info('Control request approved');
    } catch (e) {
      Logger.error('Approve control failed: $e');
      rethrow;
    }
  }

  /// 拒绝控制权请求
  Future<void> rejectControlRequest(String requestId, {String? reason}) async {
    try {
      await _updateCredentials();

      final response = await _dio.post(
        '/v1/device/control/$requestId/reject',
        options: _getAuthOptions(),
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to reject control: ${response.statusCode}');
      }

      Logger.info('Control request rejected');
    } catch (e) {
      Logger.error('Reject control failed: $e');
      rethrow;
    }
  }

  /// 发送控制权心跳
  Future<void> sendControlPing() async {
    try {
      await _updateCredentials();

      await _dio.post(
        '/v1/device/control/ping',
        options: _getAuthOptions(),
      );

      Logger.debug('Control ping sent');
    } catch (e) {
      Logger.warning('Ping failed: $e');
    }
  }

  // ========== 设备 API ==========

  /// 获取设备列表
  Future<List<DeviceInfo>> getDevices() async {
    try {
      await _updateCredentials();

      final response = await _dio.get(
        '/v1/devices',
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200) {
        final devicesJson = response.data['devices'] as List<dynamic>? ?? [];
        return devicesJson
            .map((json) => DeviceInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get devices: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Get devices failed: $e');
      rethrow;
    }
  }

  /// 获取当前设备信息
  Future<DeviceInfo?> getCurrentDevice() async {
    try {
      await _updateCredentials();

      final response = await _dio.get(
        '/v1/device/current',
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200) {
        return DeviceInfo.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get current device: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Get current device failed: $e');
      rethrow;
    }
  }

  /// 获取控制权请求列表
  Future<List<ControlRequest>> getControlRequests() async {
    try {
      await _updateCredentials();

      final response = await _dio.get(
        '/v1/device/control/requests',
        options: _getAuthOptions(),
      );

      if (response.statusCode == 200) {
        final requestsJson = response.data['requests'] as List<dynamic>? ?? [];
        return requestsJson
            .map((json) => ControlRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get control requests: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Get control requests failed: $e');
      rethrow;
    }
  }

  /// 监听控制权请求（WebSocket）
  Stream<ControlRequest> listenToControlRequests() {
    // TODO: 通过 Socket.IO 监听控制权请求
    // 返回 Stream<ControlRequest>
    return Stream.empty();
  }
}
