part of 'login_test_screen.dart';

Widget _buildLoginTestScaffold(_LoginTestScreenState state) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('登录流程测试'),
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => state.context.go(AppRoutes.home),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: state._clearLogs,
          tooltip: '清空日志',
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          _buildLoginInputArea(state),
          _buildLoginButtonArea(state),
          Expanded(child: _buildLoginLogArea(state)),
        ],
      ),
    ),
  );
}

Widget _buildLoginInputArea(_LoginTestScreenState state) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '测试链接',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: state._linkController,
          maxLines: 3,
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'happy://...',
            hintStyle: TextStyle(color: AppTheme.neutral400),
            filled: true,
            fillColor: AppTheme.neutral50,
            border: _buildLoginInputBorder(AppTheme.neutral300),
            enabledBorder: _buildLoginInputBorder(AppTheme.neutral300),
            focusedBorder:
                _buildLoginInputBorder(AppTheme.brandColor, width: 2),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持格式：happy://xxx 或 https://happy.link/xxxxx',
          style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
        ),
      ],
    ),
  );
}

Widget _buildLoginButtonArea(_LoginTestScreenState state) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildLoginActionButton(
          label: '完整流程测试',
          color: AppTheme.brandColor,
          enabled: !state._isRunning,
          onPressed: state._runFullTest,
        ),
        _buildLoginActionButton(
          label: '测试链接解析',
          color: AppTheme.neutral600,
          enabled: !state._isRunning,
          onPressed: state._testParseLink,
        ),
        _buildLoginActionButton(
          label: '测试存储',
          color: AppTheme.neutral600,
          enabled: !state._isRunning,
          onPressed: state._testStorage,
        ),
        _buildLoginActionButton(
          label: '清除凭证',
          color: Colors.red,
          enabled: !state._isRunning,
          onPressed: state._clearCredentials,
        ),
      ],
    ),
  );
}

Widget _buildLoginLogArea(_LoginTestScreenState state) {
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.black87, borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '测试日志',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('${state._logs.length} 条',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const Divider(color: Colors.grey),
        Expanded(
          child: state._logs.isEmpty
              ? const Center(
                  child: Text('暂无日志', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: state._logs.length,
                  itemBuilder: (context, index) =>
                      _buildLoginLogItem(state._logs[index]),
                ),
        ),
      ],
    ),
  );
}
