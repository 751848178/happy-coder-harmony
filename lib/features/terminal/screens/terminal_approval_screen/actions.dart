part of 'terminal_approval_screen.dart';

extension _TerminalApprovalScreenActions on _TerminalApprovalScreenState {
  Future<void> _approveRequest() async {
    _setApproving(true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    _showApprovalDialog(true);
    _setApproving(false);
  }

  void _rejectRequest() {
    _showApprovalDialog(false);
  }

  void _showApprovalDialog(bool approved) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          approved ? Icons.check_circle : Icons.cancel,
          color: approved ? AppTheme.successColor : AppTheme.errorColor,
          size: 48,
        ),
        title: Text(approved ? '已批准' : '已拒绝'),
        content: Text(
          approved
              ? '终端连接请求已被批准，${request.requestingApp} 现在可以访问终端。'
              : '终端连接请求已被拒绝，${request.requestingApp} 无法访问终端。',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}
