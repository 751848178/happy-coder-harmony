part of 'bash_tool_screen.dart';

extension _BashToolScreenOutput on _BashToolScreenState {
  Widget _buildTerminalOutput() {
    if (_outputControllers.isEmpty) {
      return Container(
        color: AppTheme.neutral900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.terminal_outlined,
                  size: 64, color: AppTheme.neutral600),
              const SizedBox(height: 16),
              const Text(
                '终端输出为空',
                style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
              ),
              const SizedBox(height: 8),
              Text(
                '输入命令开始会话',
                style: TextStyle(fontSize: 12, color: AppTheme.neutral400),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.neutral900,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _outputControllers.length,
        reverse: true,
        itemBuilder: (context, index) {
          final controller = _outputControllers[index];
          final entry = _commandHistory[_outputControllers.length - 1 - index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.brandColor,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entry.command,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.neutral400,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatTimestamp(entry.timestamp),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.neutral500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.neutral800),
                  ),
                  child: SelectableText(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommandInput() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.neutral200, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commandController,
                decoration: const InputDecoration(
                  hintText: '输入 bash 命令...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppTheme.neutral50,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _executeCommandFromInput(),
                autofocus: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isExecuting ? null : _executeCommandFromInput,
              style: IconButton.styleFrom(
                backgroundColor:
                    _isExecuting ? AppTheme.neutral300 : AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeCommandFromInput() {
    final command = _commandController.text.trim();
    if (command.isNotEmpty) {
      _executeCommand(command);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inMinutes < 60) return '${difference.inMinutes} 分钟前';
    if (difference.inHours < 24) return '${difference.inHours} 小时前';
    return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
  }
}

class BashCommand {
  const BashCommand({
    required this.command,
    required this.timestamp,
    required this.output,
  });

  final String command;
  final DateTime timestamp;
  final String output;
}
