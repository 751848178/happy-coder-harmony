part of 'push_service.dart';

class PushNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String? sessionId;
  final String? toolName;
  final String? deviceName;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.sessionId,
    this.toolName,
    this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      if (sessionId != null) 'sessionId': sessionId,
      if (toolName != null) 'toolName': toolName,
      if (deviceName != null) 'deviceName': deviceName,
    };
  }
}

enum NotificationType {
  message,
  sessionUpdate,
  toolApproval,
  controlRequest,
  controlGranted,
  controlReleased,
  buildComplete,
  unknown;

  bool get shouldAlert =>
      this == message || this == toolApproval || this == controlRequest;

  String get channelKey {
    switch (this) {
      case NotificationType.message:
        return 'message_channel';
      case NotificationType.sessionUpdate:
        return 'session_channel';
      case NotificationType.toolApproval:
        return 'tool_channel';
      case NotificationType.controlRequest:
      case NotificationType.controlGranted:
      case NotificationType.controlReleased:
        return 'control_channel';
      case NotificationType.buildComplete:
        return 'build_channel';
      default:
        return 'default_channel';
    }
  }

  String get channelTitle {
    switch (this) {
      case NotificationType.message:
        return '消息通知';
      case NotificationType.sessionUpdate:
        return '会话通知';
      case NotificationType.toolApproval:
        return '工具请求';
      case NotificationType.controlRequest:
      case NotificationType.controlGranted:
      case NotificationType.controlReleased:
        return '控制权';
      case NotificationType.buildComplete:
        return '构建状态';
      default:
        return '默认通知';
    }
  }

  String get channelDescription {
    switch (this) {
      case NotificationType.message:
        return '收到新消息时显示通知';
      case NotificationType.sessionUpdate:
        return '会话更新时显示通知';
      case NotificationType.toolApproval:
        return '有工具调用待批准时显示通知';
      case NotificationType.controlRequest:
        return '有设备请求控制权时显示通知';
      case NotificationType.controlGranted:
        return '控制权授予时显示通知';
      case NotificationType.controlReleased:
        return '控制权释放时显示通知';
      case NotificationType.buildComplete:
        return '构建完成时显示通知';
      default:
        return '通用通知';
    }
  }

  Importance get importance {
    switch (this) {
      case NotificationType.message:
      case NotificationType.toolApproval:
      case NotificationType.controlRequest:
        return Importance.high;
      case NotificationType.sessionUpdate:
      case NotificationType.controlGranted:
      case NotificationType.controlReleased:
      case NotificationType.buildComplete:
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }
}

class NotificationTap {
  final String? notificationId;
  final NotificationType type;
  final String? sessionId;

  const NotificationTap({
    this.notificationId,
    required this.type,
    this.sessionId,
  });
}
