import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../../domain/profile_state.dart';
import '../../presentation/profile_notifier.dart';
import '../../widgets/model_selector.dart';

part 'content.dart';
part 'actions.dart';
part 'factories.dart';
part 'card.dart';
part 'edit_sheet.dart';
part 'edit_sheet_init.dart';
part 'edit_sheet_content.dart';
part 'edit_sheet_provider_forms.dart';
part 'edit_sheet_dropdowns.dart';
part 'edit_sheet_save.dart';

final profileStateProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ProfileRepository.instance);
});

/// Profile list screen for managing AI backend profiles
class ProfileListScreen extends ConsumerStatefulWidget {
  const ProfileListScreen({super.key});

  @override
  ConsumerState<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends ConsumerState<ProfileListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileStateProvider.notifier).loadProfiles();
    });
  }

  void _showCreateProfileDialog() => _showProfileEditDialog();

  Future<void> _showProfileEditDialog({AIProfile? profile}) =>
      _showProfileEditBottomSheet(this, profile: profile);

  void _showProfileOptions(AIProfile profile) =>
      _showProfileOptionsSheet(this, profile);

  void _showDeleteConfirmation(AIProfile profile) =>
      _showProfileDeleteConfirmation(this, profile);

  @override
  Widget build(BuildContext context) => _buildProfileListScreen(this);
}
