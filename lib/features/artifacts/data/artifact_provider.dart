import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'artifact_repository.dart';

/// Artifact State Provider
///
/// 全局工件状态管理
final artifactStateProvider =
    StateNotifierProvider<ArtifactNotifier, ArtifactState>((ref) {
  return ArtifactNotifier(ArtifactRepository());
});

/// Artifact Repository Provider
///
/// 提供 ArtifactRepository 单例
final artifactRepositoryProvider = Provider<ArtifactRepository>((ref) {
  return ArtifactRepository();
});
