part of 'todo_tool_screen.dart';

extension _TodoToolContent on _TodoToolScreenState {
  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
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
                  onSelected: (_) {
                    _updateState(() => _selectedCategory = category);
                  },
                  backgroundColor: AppTheme.neutral100,
                  selectedColor: AppTheme.brandColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.brandColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppTheme.brandColor : AppTheme.neutral600,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }),
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
            _showCompleted ? Icons.task_alt : Icons.checklist,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            _showCompleted ? '没有已完成的任务' : '没有待办任务',
            style: const TextStyle(fontSize: 16, color: AppTheme.neutral600),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 按钮添加新任务',
            style: TextStyle(fontSize: 14, color: AppTheme.neutral400),
          ),
        ],
      ),
    );
  }
}
