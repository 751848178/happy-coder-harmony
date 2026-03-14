part of 'todo_tool_screen.dart';

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
                Checkbox(
                  value: task.completed,
                  onChanged: (_) => onTap(),
                  activeColor: AppTheme.brandColor,
                ),
                const SizedBox(width: 12),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _priorityColor.withValues(alpha: 0.3),
                              ),
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
}
