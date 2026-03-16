part of 'sessions_screen.dart';

class _SessionListItem extends StatefulWidget {
  const _SessionListItem({
    required this.session,
    required this.stats,
    required this.onTap,
    required this.onDelete,
    this.onMove,
    this.onLongPress,
    this.groupName,
  });

  final Session session;
  final SessionStats stats;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMove;
  final VoidCallback? onLongPress;
  final String? groupName;

  @override
  State<_SessionListItem> createState() => _SessionListItemState();
}

class _SessionListItemState extends State<_SessionListItem> {
  static const double _actionWidth = 78;

  double _dragExtent = 0;

  double get _maxReveal =>
      widget.onMove == null ? _actionWidth : _actionWidth * 2;

  void _closeActions() {
    if (_dragExtent == 0) {
      return;
    }
    setState(() {
      _dragExtent = 0;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    setState(() {
      _dragExtent = (_dragExtent + delta).clamp(-_maxReveal, 0.0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen =
        velocity < -220 || _dragExtent.abs() > (_maxReveal * 0.45);
    setState(() {
      _dragExtent = shouldOpen ? -_maxReveal : 0;
    });
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确认要删除会话「${widget.session.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onMove != null)
                  _SwipeActionButton(
                    width: _actionWidth,
                    color: AppTheme.infoColor,
                    icon: Icons.drive_file_move_outline,
                    label: '移动',
                    onTap: () {
                      _closeActions();
                      widget.onMove!.call();
                    },
                  ),
                _SwipeActionButton(
                  width: _actionWidth,
                  color: AppTheme.errorColor,
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  onTap: () {
                    _closeActions();
                    _confirmDelete();
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: _SessionListItemContent(
                dragExtent: _dragExtent,
                session: widget.session,
                stats: widget.stats,
                groupName: widget.groupName,
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onCloseActions: _closeActions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
