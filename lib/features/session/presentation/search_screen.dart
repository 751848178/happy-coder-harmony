import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

part 'search_screen_body.dart';
part 'search_screen_formatting.dart';

class SessionSearchScreen extends ConsumerStatefulWidget {
  const SessionSearchScreen({super.key});

  @override
  ConsumerState<SessionSearchScreen> createState() =>
      _SessionSearchScreenState();
}

class _SessionSearchScreenState extends ConsumerState<SessionSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _performSearch(String query) {
    _updateView(() => _isSearching = query.trim().isNotEmpty);
    ref.read(sessionStateProvider.notifier).loadSessions();
  }

  @override
  Widget build(BuildContext context) => _buildSessionSearchScaffold(this);
}
