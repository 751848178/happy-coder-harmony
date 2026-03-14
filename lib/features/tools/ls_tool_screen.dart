import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

part 'ls_entry_card.dart';
part 'ls_feedback_widgets.dart';
part 'ls_models.dart';
part 'ls_notifier.dart';
part 'ls_path_and_list.dart';

class LsToolScreen extends ConsumerStatefulWidget {
  const LsToolScreen({super.key});

  @override
  ConsumerState<LsToolScreen> createState() => _LsToolScreenState();
}

class _LsToolScreenState extends ConsumerState<LsToolScreen> {
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(lsNotifierProvider.notifier).listDirectory('.');
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('目录浏览'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(lsNotifierProvider.notifier).refresh(),
            tooltip: '刷新',
          ),
          PopupMenuButton<SortField>(
            onSelected: (field) {
              ref.read(lsNotifierProvider.notifier).setSort(field);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortField.name,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 18),
                    SizedBox(width: 12),
                    Text('按名称排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortField.size,
                child: Row(
                  children: [
                    Icon(Icons.storage, size: 18),
                    SizedBox(width: 12),
                    Text('按大小排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortField.modified,
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 12),
                    Text('按修改时间排序'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _PathBar(controller: _pathController),
          const Expanded(child: _EntriesList()),
        ],
      ),
    );
  }
}
