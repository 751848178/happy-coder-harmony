import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

/// Task priority
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// Task model
class Task {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? category;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
    this.category,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
    );
  }
}

/// Todo Tool Screen
///
/// Provides a task management interface
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
    // Add some sample tasks
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

  List<Task> get _filteredTasks {
    var tasks = _tasks;

    // Filter by completion status
    if (!_showCompleted) {
      tasks = tasks.where((t) => !t.completed).toList();
    }

    // Filter by category
    if (_selectedCategory != '全部') {
      tasks = tasks.where((t) => t.category == _selectedCategory).toList();
    }

    // Sort by priority and completion status
    tasks.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });

    return tasks;
  }

  int get _pendingCount => _tasks.where((t) => !t.completed).length;
  int get _completedCount => _tasks.where((t) => t.completed).length;

  void _addTask() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('请输入任务标题', isError: true);
      return;
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      createdAt: DateTime.now(),
      category: _selectedCategory == '全部' ? null : _selectedCategory,
    );

    setState(() {
      _tasks.add(task);
      _titleController.clear();
      _descriptionController.clear();
      _selectedPriority = TaskPriority.medium;
    });

    _showSnackBar('任务已添加', isError: false);
    Navigator.pop(context);
  }

  void _toggleTask(Task task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          completed: !task.completed,
          completedAt: task.completed ? null : DateTime.now(),
        );
      }
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _showSnackBar('任务已删除', isError: false);
  }

  void _editTask(Task task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑任务'),
        content: _buildTaskForm(),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _updateTask(task),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _updateTask(Task task) {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('请输入任务标题', isError: true);
      return;
    }

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _selectedPriority,
        );
      }
    });

    _showSnackBar('任务已更新', isError: false);
    Navigator.pop(context);
    _clearForm();
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedPriority = TaskPriority.medium;
  }

  void _showAddTaskDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新任务'),
        content: _buildTaskForm(),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _addTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '任务标题',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            '优先级',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildPrioritySelector(),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return SegmentedButton<TaskPriority>(
      segments: const [
        ButtonSegment(
          value: TaskPriority.low,
          label: Text('低'),
          icon: Icon(Icons.looks_one, size: 16),
        ),
        ButtonSegment(
          value: TaskPriority.medium,
          label: Text('中'),
          icon: Icon(Icons.looks_two, size: 16),
        ),
        ButtonSegment(
          value: TaskPriority.high,
          label: Text('高'),
          icon: Icon(Icons.looks_3, size: 16),
        ),
        ButtonSegment(
          value: TaskPriority.urgent,
          label: Text('紧急'),
          icon: Icon(Icons.priority_high, size: 16),
        ),
      ],
      selected: {_selectedPriority},
      onSelectionChanged: (Set<TaskPriority> newSelection) {
        setState(() => _selectedPriority = newSelection.first);
      },
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
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
                border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3)),
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
            icon: Icon(_showCompleted ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            tooltip: _showCompleted ? '隐藏已完成' : '显示已完成',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear_completed':
                  _clearCompletedTasks();
                  break;
                case 'stats':
                  _showStatsDialog();
                  break;
              }
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

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.neutral200, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...['全部', ..._categories].map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  backgroundColor: AppTheme.neutral100,
                  selectedColor: AppTheme.brandColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.brandColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskItem(
          task: task,
          onTap: () => _toggleTask(task),
          onEdit: () => _editTask(task),
          onDelete: () => _showDeleteConfirmation(task),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showCompleted
                ? Icons.task_alt
                : Icons.checklist,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            _showCompleted ? '没有已完成的任务' : '没有待办任务',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 按钮添加新任务',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  void _clearCompletedTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除已完成任务'),
        content: Text('确认要清除所有已完成的 $_completedCount 个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.removeWhere((t) => t.completed);
              });
              Navigator.pop(context);
              _showSnackBar('已清除已完成任务', isError: false);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确认要删除 "${task.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    final highPriority = _tasks.where((t) => t.priority == TaskPriority.high && !t.completed).length;
    final urgentPriority = _tasks.where((t) => t.priority == TaskPriority.urgent && !t.completed).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('任务统计'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('总任务数', _tasks.length.toString()),
              _buildStatRow('待办任务', _pendingCount.toString(), color: AppTheme.brandColor),
              _buildStatRow('已完成', _completedCount.toString(), color: AppTheme.successColor),
              const SizedBox(height: 16),
              const Text(
                '优先级分布（待办）',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildStatRow('紧急', urgentPriority.toString(), color: Colors.red),
              _buildStatRow('高优先级', highPriority.toString(), color: Colors.orange),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Task item widget
class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.low:
        return AppTheme.successColor;
      case TaskPriority.medium:
        return AppTheme.infoColor;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  String get _priorityLabel {
    switch (task.priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }

  String get _timeAgo {
    final now = DateTime.now();
    final difference = now.difference(task.createdAt);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${task.createdAt.month}/${task.createdAt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: AppTheme.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: task.completed,
                  onChanged: (_) => onTap(),
                  activeColor: AppTheme.brandColor,
                ),
                const SizedBox(width: 12),
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: task.completed
                                    ? AppTheme.neutral400
                                    : AppTheme.textPrimary,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _priorityColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPriorityIcon(),
                                  size: 12,
                                  color: _priorityColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _priorityLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _priorityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: task.completed
                                ? AppTheme.neutral400
                                : AppTheme.neutral600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral500,
                            ),
                          ),
                          if (task.category != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.label,
                              size: 12,
                              color: AppTheme.neutral500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.category!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: AppTheme.neutral600,
                  tooltip: '编辑',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case TaskPriority.low:
        return Icons.looks_one;
      case TaskPriority.medium:
        return Icons.looks_two;
      case TaskPriority.high:
        return Icons.looks_3;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }
}
