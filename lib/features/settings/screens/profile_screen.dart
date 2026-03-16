import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

part 'profile_screen_actions.dart';
part 'profile_screen_content.dart';
part 'profile_screen_rows.dart';
part 'profile_screen_sections.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() => _loadProfileUserData(this);

  String _getMachineId(dynamic credentials) =>
      _resolveProfileMachineId(credentials);

  void _showEditDialog(BuildContext context) =>
      _showProfileEditDialog(this, context);

  Future<void> _shareApp() => _shareProfileApp(this);

  @override
  Widget build(BuildContext context) {
    return _buildProfileScaffold(this);
  }
}
