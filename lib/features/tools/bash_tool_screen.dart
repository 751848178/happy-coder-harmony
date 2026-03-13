import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// Bash Tool Screen
///
/// Provides a terminal interface for executing bash commands
class BashToolScreen extends ConsumerStatefulWidget {
  const BashToolScreen({super.key});

  @override
  ConsumerState<BashToolScreen> createState() => _BashToolScreenState();
}

class _BashToolScreenState extends ConsumerState<BashToolScreen> {
  final _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<BashCommand> _commandHistory = [];
  final List<TextEditingController> _outputControllers = [];

  bool _isExecuting = false;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _commandHistory.add(BashCommand(
      command: 'pwd',
      timestamp: DateTime.now(),
      output: '/home/user/project',
    ));
    _outputControllers.add(TextEditingController(text: '/home/user/project'));
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    for (final controller in _outputControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _executeCommand(String command) async {
    if (_isExecuting) return;

    setState(() => _isExecuting = true);

    try {
      // Simulate command execution (in real app, this would use a terminal backend)
      await Future.delayed(const Duration(milliseconds: 500));

      final result = await _executeBashCommand(command);

      setState(() {
        _isExecuting = false;
        _selectedIndex = _commandHistory.length;
        _outputControllers.add(TextEditingController(text: result));

        if (_selectedIndex == 0) {
          // First command - show as current
          _scrollController.jumpTo(0.0);
        }
      });

      _commandHistory.add(BashCommand(
        command: command,
        timestamp: DateTime.now(),
        output: result,
      ));

      _commandController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('命令执行完成'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExecuting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('命令执行失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<String> _executeBashCommand(String command) async {
    // In a real app, this would call the backend API
    // For now, we'll simulate some responses

    if (command.startsWith('ls')) {
      return 'file1.txt\nfile2.txt\nfile3.txt';
    } else if (command.startsWith('pwd')) {
      return '/home/user/project';
    } else if (command.startsWith('cd')) {
      return 'Changed directory';
    } else if (command.startsWith('cat')) {
      return 'File content goes here...\n[EOF]';
    } else if (command.startsWith('echo')) {
      return command.substring(5);
    } else if (command.startsWith('mkdir')) {
      return 'Directory created';
    } else if (command.startsWith('rm')) {
      return 'File/Directory removed';
    } else if (command.startsWith('clear')) {
      return 'Terminal cleared';
    } else if (command.startsWith('whoami')) {
      return 'user@hostname';
    } else if (command.startsWith('date')) {
      return DateTime.now().toString();
    } else {
      return 'Unknown command: $command';
    }
  }

  void _clearTerminal() {
    setState(() {
      _outputControllers.clear();
      _selectedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('终端'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _clearTerminal();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('终端已清空'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            tooltip: '清空终端',
          ),
        ],
      ),
      body: Column(
        children: [
          // Terminal output area
          Expanded(
            child: _buildTerminalOutput(),
          ),
          // Command input area
          _buildCommandInput(),
        ],
      ),
    );
  }

  Widget _buildTerminalOutput() {
    if (_outputControllers.isEmpty) {
      return Container(
        color: AppTheme.neutral900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.terminal_outlined,
                size: 64,
                color: AppTheme.neutral600,
              ),
              const SizedBox(height: 16),
              const Text(
                '终端输出为空',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '输入命令开始会话',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral400,
                ),
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
          final commandEntry = _commandHistory[_outputControllers.length - 1 - index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Prompt indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        commandEntry.command,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.neutral400,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatTimestamp(commandEntry.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Output
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.neutral200, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commandController,
                decoration: InputDecoration(
                  hintText: '输入 bash 命令...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppTheme.neutral50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) => _executeCommandFromInput(),
                autofocus: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isExecuting ? null : _executeCommandFromInput,
              style: IconButton.styleFrom(
                backgroundColor: _isExecuting ? AppTheme.neutral300 : AppTheme.brandColor,
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
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
    }
  }
}

/// Bash command model
class BashCommand {
  final String command;
  final DateTime timestamp;
  final String output;

  const BashCommand({
    required this.command,
    required this.timestamp,
    required this.output,
  });
}
