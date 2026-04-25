part of 'artifact_repository.dart';

/// Artifact State Provider
///
/// 管理工件状态和列表
class ArtifactNotifier extends StateNotifier<ArtifactState> {
  ArtifactNotifier(this._repository) : super(const ArtifactState.initial());

  final ArtifactRepository _repository;

  /// 加载工件列表
  Future<void> loadArtifacts({String? cursor, int limit = 100}) async {
    state = const ArtifactState.loading();
    try {
      final response = await _repository.listArtifacts(
        limit: limit,
        cursor: cursor,
      );
      state = ArtifactState.loaded(
        artifacts: response.items,
        nextCursor: response.nextCursor,
      );
    } catch (e) {
      state = ArtifactState.error(e.toString());
    }
  }

  /// 加载单个工件
  Future<Artifact?> loadArtifact(String id) async {
    try {
      final artifact = await _repository.getArtifact(id);
      final currentArtifacts = [...state.artifacts];
      final index = currentArtifacts.indexWhere((item) => item.id == id);
      if (index == -1) {
        currentArtifacts.insert(0, artifact);
      } else {
        currentArtifacts[index] = artifact;
      }
      state = ArtifactState.loaded(
        artifacts: currentArtifacts,
        nextCursor: state.nextCursor,
      );
      return artifact;
    } catch (e) {
      state = ArtifactState.error(e.toString());
      return null;
    }
  }

  /// 创建工件
  Future<Artifact?> createArtifact(CreateArtifactRequest request) async {
    final previousArtifacts = [...state.artifacts];
    final previousCursor = state.nextCursor;
    try {
      final artifact = await _repository.createArtifact(request);
      state = ArtifactState.loaded(
        artifacts: [
          artifact,
          ...previousArtifacts.where((item) => item.id != artifact.id),
        ],
        nextCursor: previousCursor,
      );
      return artifact;
    } catch (e) {
      state = ArtifactState.error(e.toString());
      return null;
    }
  }

  /// 更新工件
  Future<Artifact?> updateArtifact(
    String id,
    UpdateArtifactRequest request,
  ) async {
    try {
      final artifact = await _repository.updateArtifact(id, request);
      final currentArtifacts = [...state.artifacts];
      final index = currentArtifacts.indexWhere((item) => item.id == id);
      if (index == -1) {
        currentArtifacts.insert(0, artifact);
      } else {
        currentArtifacts[index] = artifact;
      }
      state = ArtifactState.loaded(
        artifacts: currentArtifacts,
        nextCursor: state.maybeWhen<String?>(
              loaded: (_, nextCursor) => nextCursor,
              orElse: () => null,
            ) ??
            state.nextCursor,
      );
      return artifact;
    } catch (e) {
      state = ArtifactState.error(e.toString());
      return null;
    }
  }

  /// 删除工件
  Future<void> deleteArtifact(String id) async {
    try {
      await _repository.deleteArtifact(id);
      final currentArtifacts = state.maybeWhen(
            loaded: (artifacts, _) =>
                artifacts.where((artifact) => artifact.id != id).toList(),
            orElse: () => <Artifact>[],
          ) ??
          <Artifact>[];
      state = ArtifactState.loaded(
        artifacts: currentArtifacts,
        nextCursor: state.maybeWhen<String?>(
          loaded: (_, nextCursor) => nextCursor,
          orElse: () => null,
        ),
      );
    } catch (e) {
      state = ArtifactState.error(e.toString());
    }
  }
}
