part of 'notifications_settings_screen.dart';

Widget _buildNotificationsSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.neutral600,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget _buildNotificationSwitchTile({
  required IconData icon,
  required String title,
  String? subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: AppTheme.brandColor, size: 22),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppTheme.neutral900,
      ),
    ),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
          ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppTheme.brandColor,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

Widget _buildDoNotDisturbTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required int startHour,
  required int endHour,
  required void Function(int, int) onTimeChanged,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: AppTheme.brandColor, size: 22),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppTheme.neutral900,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
    ),
    trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
    onTap: () => _showDoNotDisturbDialog(
      context,
      startHour,
      endHour,
      onTimeChanged,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

void _showDoNotDisturbDialog(
  BuildContext context,
  int startHour,
  int endHour,
  void Function(int, int) onTimeChanged,
) {
  var tempStart = startHour;
  var tempEnd = endHour;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('设置免打扰时段'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('开始时间'),
          _DoNotDisturbWheel(
            selectedHour: startHour,
            onSelected: (value) => tempStart = value,
          ),
          const SizedBox(height: 16),
          const Text('结束时间'),
          _DoNotDisturbWheel(
            selectedHour: endHour,
            onSelected: (value) => tempEnd = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            onTimeChanged(tempStart, tempEnd);
            Navigator.pop(dialogContext);
          },
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

class _DoNotDisturbWheel extends StatelessWidget {
  const _DoNotDisturbWheel({
    required this.selectedHour,
    required this.onSelected,
  });

  final int selectedHour;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 24,
          builder: (context, index) {
            return Center(
              child: Text(
                '${index.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: index == selectedHour ? 20 : 16,
                  fontWeight: index == selectedHour
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
