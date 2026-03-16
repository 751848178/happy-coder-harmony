part of 'login_test_screen.dart';

OutlineInputBorder _buildLoginInputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: width),
  );
}

Widget _buildLoginActionButton({
  required String label,
  required Color color,
  required bool enabled,
  required VoidCallback? onPressed,
}) {
  return ElevatedButton(
    onPressed: enabled ? onPressed : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(label),
  );
}

Widget _buildLoginLogItem(TestLog log) {
  final (icon, textColor) = switch (log.level) {
    LogType.info => (Icons.info_outline, Colors.lightBlue),
    LogType.success => (Icons.check_circle_outline, Colors.green),
    LogType.warning => (Icons.warning_amber_outlined, Colors.orange),
    LogType.error => (Icons.error_outline, Colors.red),
  };
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    log.step,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatLoginTestTime(log.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(log.message,
                  style: TextStyle(color: textColor, fontSize: 12)),
              if (log.details != null) ...[
                const SizedBox(height: 2),
                Text(
                  log.details!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatLoginTestTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}.'
      '${time.millisecond.toString().padLeft(3, '0')}';
}
