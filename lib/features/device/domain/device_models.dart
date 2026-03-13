/// 设备控制模型
///

/// 设备状态
enum DeviceStatus {
  /// 空闲
  idle,
  /// 请求控制权
  requestingControl,
  /// 拥有控制权
  hasControl,
  /// 控制权被占用
  controlTaken,
}

/// 设备信息
class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final bool isActive;
  final DateTime lastSeenAt;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    this.isActive = false,
    required this.lastSeenAt,
  });

  DeviceInfo copyWith({
    String? id,
    String? name,
    String? platform,
    bool? isActive,
    DateTime? lastSeenAt,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      isActive: isActive ?? this.isActive,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'isActive': isActive,
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      isActive: json['isActive'] as bool? ?? false,
      lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
    );
  }
}

/// 控制权请求
class ControlRequest {
  final String id;
  final String requestingDeviceId;
  final String requestingDeviceName;
  final String targetDeviceId;
  final DateTime createdAt;
  final ControlRequestStatus status;

  const ControlRequest({
    required this.id,
    required this.requestingDeviceId,
    required this.requestingDeviceName,
    required this.targetDeviceId,
    required this.createdAt,
    this.status = ControlRequestStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestingDeviceId': requestingDeviceId,
      'requestingDeviceName': requestingDeviceName,
      'targetDeviceId': targetDeviceId,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory ControlRequest.fromJson(Map<String, dynamic> json) {
    return ControlRequest(
      id: json['id'] as String,
      requestingDeviceId: json['requestingDeviceId'] as String,
      requestingDeviceName: json['requestingDeviceName'] as String,
      targetDeviceId: json['targetDeviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ControlRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ControlRequestStatus.pending,
      ),
    );
  }
}

/// 控制权请求状态
enum ControlRequestStatus {
  pending,
  approved,
  rejected,
  expired,
  canceled,
}

/// 控制权状态
class ControlState {
  final DeviceStatus deviceStatus;
  final String? controllingDeviceId;
  final String? controllingDeviceName;
  final DateTime? controlAcquiredAt;
  final ControlRequest? pendingRequest;

  const ControlState({
    this.deviceStatus = DeviceStatus.idle,
    this.controllingDeviceId,
    this.controllingDeviceName,
    this.controlAcquiredAt,
    this.pendingRequest,
  });

  ControlState copyWith({
    DeviceStatus? deviceStatus,
    String? controllingDeviceId,
    String? controllingDeviceName,
    DateTime? controlAcquiredAt,
    ControlRequest? pendingRequest,
  }) {
    return ControlState(
      deviceStatus: deviceStatus ?? this.deviceStatus,
      controllingDeviceId: controllingDeviceId ?? this.controllingDeviceId,
      controllingDeviceName: controllingDeviceName ?? this.controllingDeviceName,
      controlAcquiredAt: controlAcquiredAt ?? this.controlAcquiredAt,
      pendingRequest: pendingRequest ?? this.pendingRequest,
    );
  }

  bool get hasControl => deviceStatus == DeviceStatus.hasControl;
  bool get controlTaken => deviceStatus == DeviceStatus.controlTaken;
  bool get isIdle => deviceStatus == DeviceStatus.idle;
  bool get hasPendingRequest => pendingRequest != null;

  /// 检查是否需要响应
  bool needsResponse() {
    return deviceStatus == DeviceStatus.requestingControl ||
           pendingRequest?.status == ControlRequestStatus.pending;
  }

  /// 计算控制权时长
  Duration? get controlDuration {
    if (controlAcquiredAt == null) return null;
    return DateTime.now().difference(controlAcquiredAt!);
  }
}
