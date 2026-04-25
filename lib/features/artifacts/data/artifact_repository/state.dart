part of 'artifact_repository.dart';

/// Artifact State
///
/// 工件状态枚举
class ArtifactState {
  final List<Artifact> artifacts;
  final String? nextCursor;
  final String? error;

  const ArtifactState({
    this.artifacts = const [],
    this.nextCursor,
    this.error,
  });

  const ArtifactState.initial()
      : artifacts = const [],
        nextCursor = null,
        error = null;

  const ArtifactState.loading()
      : artifacts = const [],
        nextCursor = null,
        error = null;

  const ArtifactState.loaded({
    required this.artifacts,
    this.nextCursor,
    this.error = null,
  });

  const ArtifactState.error(String errorMessage)
      : artifacts = const [],
        nextCursor = null,
        error = errorMessage;

  bool get isLoading =>
      artifacts.isEmpty && error == null && nextCursor == null;

  bool get hasError => error != null;

  bool get isLoaded => artifacts.isNotEmpty && error == null;

  T? when<T>({
    T Function()? initial,
    required T Function(List<Artifact>, String?) loaded,
    required T Function(String) error,
  }) {
    if (hasError) {
      return error(this.error!);
    }
    if (isLoaded) {
      return loaded(artifacts, nextCursor);
    }
    return initial?.call();
  }

  T? maybeWhen<T>({
    T Function()? orElse,
    T Function(List<Artifact>, String?)? loaded,
    T Function(String)? error,
  }) {
    if (hasError && error != null) {
      return error.call(this.error!);
    }
    if (isLoaded && loaded != null) {
      return loaded.call(artifacts, nextCursor);
    }
    return orElse?.call();
  }
}
