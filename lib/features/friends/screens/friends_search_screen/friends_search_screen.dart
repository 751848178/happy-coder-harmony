import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/auth_models.dart' show UserSearchResult;
import '../../data/friends_repository.dart';

part 'body.dart';

class FriendsSearchScreen extends ConsumerStatefulWidget {
  const FriendsSearchScreen({super.key});

  @override
  ConsumerState<FriendsSearchScreen> createState() =>
      _FriendsSearchScreenState();
}

class _FriendsSearchScreenState extends ConsumerState<FriendsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserSearchResult> _results = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final token = ref.read(authStateProvider).credentials?.token;
      final users = await FriendsRepository.instance.searchUsers(
        trimmed,
        token: token,
      );
      setState(() {
        _results = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isSearching = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  Future<void> _addFriend(UserSearchResult user) async {
    try {
      final token = ref.read(authStateProvider).credentials?.token;
      await FriendsRepository.instance.addFriend(user.id, token: token);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已向 ${user.name} 发送好友请求'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发送好友请求失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('添加好友'),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入用户名或 GitHub 用户名',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ListenableBuilder(
                  listenable: _searchController,
                  builder: (context, _) {
                    if (_searchController.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                      icon: const Icon(Icons.close),
                    );
                  },
                ),
                filled: true,
                fillColor: AppTheme.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
