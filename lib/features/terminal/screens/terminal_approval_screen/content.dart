part of 'terminal_approval_screen.dart';

extension _TerminalApprovalScreenContent on _TerminalApprovalScreenState {
  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderIcon(),
        const SizedBox(height: 24),
        const Text(
          '终端连接请求',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${request.requestingApp} 请求访问终端连接',
          style: const TextStyle(fontSize: 15, color: AppTheme.neutral600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildDetailsCard(),
        const SizedBox(height: 24),
        _buildWarning(),
        const SizedBox(height: 24),
        _buildRememberOption(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandColor,
            AppTheme.brandColor.withValues(alpha: 0.7)
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.terminal, size: 40, color: Colors.white),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(icon: Icons.computer, label: '主机', value: request.machine),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.folder, label: '路径', value: request.path),
          if (request.command != null) ...[
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.code, label: '命令', value: request.command!),
          ],
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.access_time,
            label: '请求时间',
            value: _formatTime(request.requestedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '批准后，该应用将获得终端访问权限。请确认您信任此应用。',
              style: TextStyle(fontSize: 13, color: AppTheme.neutral700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberOption() {
    return InkWell(
      onTap: () => _setRemembered(!_isRemembered),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _isRemembered,
              onChanged: (value) => _setRemembered(value ?? false),
              activeColor: AppTheme.brandColor,
            ),
            const SizedBox(width: 8),
            const Text(
              '记住此决定',
              style: TextStyle(fontSize: 14, color: AppTheme.neutral700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isApproving ? null : _rejectRequest,
            icon: const Icon(Icons.close),
            label: const Text('拒绝'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isApproving ? null : _approveRequest,
            icon: _isApproving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isApproving ? '处理中...' : '批准'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.month}/${time.day} $hour:$minute';
  }
}
