import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

part 'todo_models.dart';
part 'todo_task_item.dart';
part 'todo_task_item_helpers.dart';
part 'todo_tool_actions.dart';
part 'todo_tool_content.dart';
part 'todo_tool_dialogs.dart';
part 'todo_tool_stats.dart';

class TodoToolScreen extends ConsumerStatefulWidget {
  const TodoToolScreen({super.key});

  @override
  ConsumerState<TodoToolScreen> createState() => _TodoToolScreenState();
}

class _TodoToolScreenState extends ConsumerState<TodoToolScreen> {
  final List<Task> _tasks = [];
  final List<String> _categories = ['工作', '个人', '学习', '其他'];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _showCompleted = false;
  String _selectedCategory = '全部';
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _tasks.addAll([
      Task(
        id: '1',
        title: '完成 Flutter 项目开发',
        description: '实现所有核心功能模块',
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        category: '工作',
      ),
      Task(
        id: '2',
        title: '阅读技术文档',
        description: '学习最新的 API 更新',
        priority: TaskPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        category: '学习',
      ),
      Task(
        id: '3',
        title: '健身',
        description: '去健身房锻炼 1 小时',
        priority: TaskPriority.low,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        category: '个人',
        completed: true,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateState(VoidCallback update) {
    setState(update);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('任务管理'),
        actions: [
          if (_pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.brandColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pending_actions,
                    size: 16,
                    color: AppTheme.brandColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_pendingCount 待办',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.brandColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                _updateState(() => _showCompleted = !_showCompleted),
            tooltip: _showCompleted ? '隐藏已完成' : '显示已完成',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_completed') {
                _clearCompletedTasks();
                return;
              }
              _showStatsDialog();
            },
            itemBuilder: (context) => [
              if (_completedCount > 0)
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 18),
                      SizedBox(width: 12),
                      Text('清除已完成'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 18),
                    SizedBox(width: 12),
                    Text('统计信息'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : _buildTaskList(filteredTasks),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('添加任务'),
      ),
    );
  }
}
