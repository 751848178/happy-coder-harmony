import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../artifacts/data/artifact_provider.dart';
import '../../artifacts/data/artifact_repository.dart';
import '../../artifacts/domain/artifact_display.dart';
import '../../artifacts/domain/artifact_models.dart';

part 'artifacts_list_screen_row.dart';

/// Upstream-aligned artifacts list.
class ArtifactsListScreen extends ConsumerStatefulWidget {
  const ArtifactsListScreen({super.key});

  @override
  ConsumerState<ArtifactsListScreen> createState() =>
      _ArtifactsListScreenState();
}

class _ArtifactsListScreenState extends ConsumerState<ArtifactsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artifactStateProvider.notifier).loadArtifacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artifactStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('工件'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(artifactStateProvider.notifier).loadArtifacts(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/artifacts/new'),
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ArtifactState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text(
                state.error ?? '加载失败',
                style: const TextStyle(color: AppTheme.neutral700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.artifacts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 64, color: AppTheme.neutral400),
              SizedBox(height: 12),
              Text(
                '暂无工件',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '点击右下角按钮创建第一条工件记录。',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final artifacts = List<Artifact>.from(state.artifacts)
      ..sort((Artifact a, Artifact b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: artifacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final artifact = artifacts[index];
        final isFirst = index == 0;
        final isLast = index == artifacts.length - 1;
        return _ArtifactRow(
          artifact: artifact,
          isFirst: isFirst,
          isLast: isLast,
          onTap: () => context.push('/artifacts/${artifact.id}'),
        );
      },
    );
  }
}
