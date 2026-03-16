part of 'app_router.dart';

List<RouteBase> _buildArtifactRoutes() {
  return [
    GoRoute(
      path: AppRoutes.artifacts,
      name: AppRoutes.artifactsName,
      builder: (context, state) => const ArtifactsListScreen(),
    ),
    GoRoute(
      path: '/artifacts/index',
      builder: (context, state) => const ArtifactsListScreen(),
    ),
    GoRoute(
      path: AppRoutes.artifactDetail,
      name: AppRoutes.artifactDetailName,
      builder: (context, state) => _buildRequiredPathWidget(
        state.pathParameters['id'],
        (id) => ArtifactDetailScreen(artifactId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.newArtifact,
      name: AppRoutes.newArtifactName,
      builder: (context, state) => const NewArtifactScreen(),
    ),
    GoRoute(
      path: AppRoutes.editArtifact,
      name: AppRoutes.editArtifactName,
      builder: (context, state) => _buildRequiredPathWidget(
        state.pathParameters['id'],
        (id) => EditArtifactScreen(artifactId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.fileViewer,
      name: AppRoutes.fileViewerName,
      builder: (context, state) => _buildFileViewerRoute(state),
    ),
  ];
}
