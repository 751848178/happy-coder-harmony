import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

part 'enhanced_new_session_screen_logic.dart';
part 'enhanced_new_session_screen_steps.dart';
part 'enhanced_new_session_screen_step_content.dart';
part 'enhanced_new_session_screen_template_widgets.dart';
part 'enhanced_new_session_screen_machine_widgets.dart';
part 'enhanced_new_session_screen_profile_widgets.dart';
part 'enhanced_new_session_screen_mode_widgets.dart';
part 'enhanced_new_session_screen_models.dart';

/// Enhanced New Session Screen
///
/// 增强版新建会话屏幕，支持机器选择、路径选择、配置文件编辑
class EnhancedNewSessionScreen extends ConsumerStatefulWidget {
  const EnhancedNewSessionScreen({
    super.key,
    this.initialMachineId,
    this.initialPath,
    this.initialProfileId,
  });

  final String? initialMachineId;
  final String? initialPath;
  final String? initialProfileId;

  @override
  ConsumerState<EnhancedNewSessionScreen> createState() =>
      _EnhancedNewSessionScreenState();
}

class _EnhancedNewSessionScreenState
    extends ConsumerState<EnhancedNewSessionScreen> {
  int _currentStep = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedTag = 'general';
  String? _selectedMachineId;
  final List<Machine> _availableMachines = [];
  final TextEditingController _pathController = TextEditingController();
  List<String> _recentPaths = [];
  String? _selectedProfileId;
  final List<ProfileSummary> _availableProfiles = [];
  String _permissionMode = 'auto';
  String _modelMode = 'auto';

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      _pathController.text = widget.initialPath!;
    }
    _loadAvailableMachines();
    _loadAvailableProfiles();
    _loadRecentPaths();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _loadAvailableMachines() => _loadEnhancedAvailableMachines(this);

  Future<void> _loadAvailableProfiles() => _loadEnhancedAvailableProfiles(this);

  Future<void> _loadRecentPaths() => _loadEnhancedRecentPaths(this);

  void _nextStep() => _advanceEnhancedStep(this);

  Future<void> _createSession() => _createEnhancedSession(this);

  Future<void> _showPathPicker() => _showEnhancedPathPicker(this);

  Future<void> _editProfile(String profileId) =>
      _editEnhancedProfile(this, profileId);

  Future<void> _pickMachine() => _pickEnhancedMachine(this);

  @override
  Widget build(BuildContext context) => _buildEnhancedNewSessionScreen(this);
}
