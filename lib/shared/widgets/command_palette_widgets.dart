part of 'command_palette.dart';

class _CommandItemWidget extends StatelessWidget {
  const _CommandItemWidget({
    required this.command,
    required this.isSelected,
    required this.onTap,
  });

  final CommandItem command;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                command.icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.neutral600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    command.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.brandColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (command.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      command.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppTheme.brandColor.withValues(alpha: 0.7)
                            : AppTheme.neutral500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if ((command.subcommands ?? const <CommandItem>[]).isNotEmpty)
              Icon(
                Icons.chevron_right,
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral400,
              ),
          ],
        ),
      ),
    );
  }
}

class _CommandPaletteOverlay extends StatelessWidget {
  const _CommandPaletteOverlay({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: visible
          ? Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Center(child: child),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _ArrowDownIntent extends Intent {
  const _ArrowDownIntent();
}

class _ArrowUpIntent extends Intent {
  const _ArrowUpIntent();
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}
