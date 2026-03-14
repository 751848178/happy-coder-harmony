part of 'todo_tool_screen.dart';

extension _TodoToolStats on _TodoToolScreenState {
  void _showStatsDialog() {
    final highPriority = _tasks
        .where((task) => task.priority == TaskPriority.high && !task.completed)
        .length;
    final urgentPriority = _tasks
        .where(
          (task) => task.priority == TaskPriority.urgent && !task.completed,
        )
        .length;

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
              _buildStatRow(
                '待办任务',
                _pendingCount.toString(),
                color: AppTheme.brandColor,
              ),
              _buildStatRow(
                '已完成',
                _completedCount.toString(),
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              const Text(
                '优先级分布（待办）',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildStatRow('紧急', urgentPriority.toString(), color: Colors.red),
              _buildStatRow(
                '高优先级',
                highPriority.toString(),
                color: Colors.orange,
              ),
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
            style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
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
