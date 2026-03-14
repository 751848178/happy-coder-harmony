part of 'todo_tool_screen.dart';

extension _TodoToolDialogs on _TodoToolScreenState {
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
          const Text('优先级', style: TextStyle(fontWeight: FontWeight.w500)),
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
      onSelectionChanged: (selection) {
        _updateState(() => _selectedPriority = selection.first);
      },
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
              _updateState(() {
                _tasks.removeWhere((task) => task.completed);
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
}
