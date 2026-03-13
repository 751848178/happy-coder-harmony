import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/domain/profile_models.dart';
import '../../profile/domain/profile_state.dart';
import '../../profile/screens/profile_list_screen.dart';

/// 会话向导中的配置文件选择/编辑页
class SessionProfileEditScreen extends ConsumerStatefulWidget {
  const SessionProfileEditScreen({
    super.key,
    this.selectedProfileId,
    this.agent,
  });

  final String? selectedProfileId;
  final String? agent;

  @override
  ConsumerState<SessionProfileEditScreen> createState() =>
      _SessionProfileEditScreenState();
}

class _SessionProfileEditScreenState
    extends ConsumerState<SessionProfileEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileStateProvider.notifier).loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileStateProvider);
    final allProfiles = state is ProfileLoaded ? state.profiles : <AIProfile>[];
    final profiles = widget.agent == null || widget.agent!.isEmpty
        ? allProfiles
        : allProfiles
            .where((profile) => profile.isCompatibleWith(widget.agent!))
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('选择配置文件'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.settingsProfiles),
            child: const Text('管理'),
          ),
        ],
      ),
      body: profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.agent == null || widget.agent!.isEmpty
                        ? '暂无可用配置文件'
                        : '当前没有可用于 ${widget.agent} 的配置文件',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.settingsProfiles),
                    child: const Text('前往创建'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final isSelected = profile.id == widget.selectedProfileId;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.brandColor
                          : AppTheme.neutral200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(profile.name),
                    subtitle: Text(
                      profile.description ??
                          profile.providerDisplayName ??
                          '无描述',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => context.push(
                            AppRoutes.profileDetailWithId(profile.id),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.brandColor,
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(profile.id),
                  ),
                );
              },
            ),
    );
  }
}
