part of 'todo_tool_screen.dart';

extension _TodoToolActions on _TodoToolScreenState {
  List<Task> get _filteredTasks {
    var tasks = _tasks;
    if (!_showCompleted) {
      tasks = tasks.where((task) => !task.completed).toList();
    }
    if (_selectedCategory != '全部') {
      tasks =
          tasks.where((task) => task.category == _selectedCategory).toList();
    }
    tasks.sort((left, right) {
      if (left.completed != right.completed) {
        return left.completed ? 1 : -1;
      }
      return right.priority.index.compareTo(left.priority.index);
    });
    return tasks;
  }

  int get _pendingCount => _tasks.where((task) => !task.completed).length;
  int get _completedCount => _tasks.where((task) => task.completed).length;

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

    _updateState(() {
      _tasks.add(task);
      _titleController.clear();
      _descriptionController.clear();
      _selectedPriority = TaskPriority.medium;
    });

    _showSnackBar('任务已添加', isError: false);
    Navigator.pop(context);
  }

  void _toggleTask(Task task) {
    _updateState(() {
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(
          completed: !task.completed,
          completedAt: task.completed ? null : DateTime.now(),
        );
      }
    });
  }

  void _deleteTask(Task task) {
    _updateState(() {
      _tasks.removeWhere((item) => item.id == task.id);
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

    _updateState(() {
      final index = _tasks.indexWhere((item) => item.id == task.id);
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

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }
}
