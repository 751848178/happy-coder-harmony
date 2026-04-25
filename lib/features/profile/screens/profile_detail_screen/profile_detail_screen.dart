import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_state.dart';
import '../profile_list_screen.dart';

part 'environment.dart';
part 'load_save.dart';
part 'provider_config.dart';
part 'sections.dart';

/// Profile Detail Screen
///
/// Displays detailed profile configuration with environment variables
class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<EnvironmentVariable> _environmentVariables = [];
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _valueControllers = [];

  AIProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateView(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);
    final profiles =
        profileState is ProfileLoaded ? profileState.profiles : <AIProfile>[];

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(_profile?.name ?? '配置详情'),
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (_profile != null && !_profile!.isBuiltIn) {
                  _showEditDialog();
                }
              },
              tooltip: '编辑',
            ),
        ],
      ),
      body: _isLoading || _profile == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(profiles),
    );
  }
}
