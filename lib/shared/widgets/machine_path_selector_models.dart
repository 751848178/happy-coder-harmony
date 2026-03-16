part of 'machine_path_selector.dart';

class MachineInfo {
  const MachineInfo({
    required this.id,
    required this.name,
    required this.host,
    this.iconPath,
    this.isLocal = false,
    this.isOnline = true,
    this.sshKey,
  });

  final String id;
  final String name;
  final String host;
  final String? iconPath;
  final bool isLocal;
  final bool isOnline;
  final String? sshKey;

  MachineInfo copyWith({
    String? id,
    String? name,
    String? host,
    String? iconPath,
    bool? isLocal,
    bool? isOnline,
    String? sshKey,
  }) {
    return MachineInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      iconPath: iconPath ?? this.iconPath,
      isLocal: isLocal ?? this.isLocal,
      isOnline: isOnline ?? this.isOnline,
      sshKey: sshKey ?? this.sshKey,
    );
  }
}

class PathInfo {
  const PathInfo({
    required this.path,
    required this.label,
    required this.icon,
    this.isFavorite = false,
    this.recentIndex,
  });

  final String path;
  final String label;
  final IconData icon;
  final bool isFavorite;
  final int? recentIndex;

  String get displayName => label.isEmpty ? path : label;
}

class BuiltInMachines {
  static const all = [
    MachineInfo(
      id: 'local',
      name: '本地机器',
      host: 'localhost',
      isLocal: true,
      isOnline: true,
    ),
  ];

  static MachineInfo? byId(String id) {
    for (final machine in all) {
      if (machine.id == id) return machine;
    }
    return null;
  }
}

class BuiltInPaths {
  static const all = [
    PathInfo(path: '/', label: '根目录', icon: Icons.home),
    PathInfo(path: '/home', label: '用户目录', icon: Icons.person),
    PathInfo(path: '/tmp', label: '临时目录', icon: Icons.folder),
    PathInfo(path: '/var/log', label: '日志目录', icon: Icons.description),
    PathInfo(path: '/etc', label: '配置目录', icon: Icons.settings),
  ];

  static const recentPaths = [
    PathInfo(
      path: '/home/user/project',
      label: 'project',
      icon: Icons.code,
      recentIndex: 0,
    ),
    PathInfo(
      path: '/home/user/work',
      label: 'work',
      icon: Icons.work,
      recentIndex: 1,
    ),
    PathInfo(
      path: '/home/user/documents',
      label: 'documents',
      icon: Icons.folder_open,
      recentIndex: 2,
    ),
    PathInfo(
      path: '/home/user/downloads',
      label: 'downloads',
      icon: Icons.download,
      recentIndex: 3,
    ),
  ];
}
