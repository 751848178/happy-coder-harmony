part of 'profile_models.dart';

/// Default permission mode for profile
enum PermissionMode {
  defaultMode,
  acceptEdits,
  bypassPermissions,
  plan,
  readOnly,
  safeYolo,
  yolo;

  String get displayName {
    switch (this) {
      case PermissionMode.defaultMode:
        return '默认';
      case PermissionMode.acceptEdits:
        return '接受编辑';
      case PermissionMode.bypassPermissions:
        return '绕过权限';
      case PermissionMode.plan:
        return '计划模式';
      case PermissionMode.readOnly:
        return '只读';
      case PermissionMode.safeYolo:
        return '安全快速';
      case PermissionMode.yolo:
        return '完全自动';
    }
  }

  String get value {
    switch (this) {
      case PermissionMode.defaultMode:
        return 'default';
      case PermissionMode.acceptEdits:
        return 'acceptEdits';
      case PermissionMode.bypassPermissions:
        return 'bypassPermissions';
      case PermissionMode.plan:
        return 'plan';
      case PermissionMode.readOnly:
        return 'read-only';
      case PermissionMode.safeYolo:
        return 'safe-yolo';
      case PermissionMode.yolo:
        return 'yolo';
    }
  }

  static PermissionMode fromString(String value) {
    switch (value) {
      case 'acceptEdits':
        return PermissionMode.acceptEdits;
      case 'bypassPermissions':
        return PermissionMode.bypassPermissions;
      case 'plan':
        return PermissionMode.plan;
      case 'read-only':
        return PermissionMode.readOnly;
      case 'safe-yolo':
        return PermissionMode.safeYolo;
      case 'yolo':
        return PermissionMode.yolo;
      default:
        return PermissionMode.defaultMode;
    }
  }
}

/// Default session type for profile
enum SessionType {
  simple,
  worktree;

  String get displayName {
    switch (this) {
      case SessionType.simple:
        return '简单会话';
      case SessionType.worktree:
        return '工作树';
    }
  }

  String get value {
    switch (this) {
      case SessionType.simple:
        return 'simple';
      case SessionType.worktree:
        return 'worktree';
    }
  }

  static SessionType fromString(String value) {
    switch (value) {
      case 'worktree':
        return SessionType.worktree;
      default:
        return SessionType.simple;
    }
  }
}
