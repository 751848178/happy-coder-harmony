import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

part 'bash_tool_screen_output.dart';

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

  final ValueNotifier<bool> _isExecuting = ValueNotifier(false);
  int _selectedIndex = -1;

  bool get _executing => _isExecuting.value;

  @override
  void initState() {
    super.initState();
    _addCommandResult('pwd', '/home/user/project');
  }

  @override
  void dispose() {
    _isExecuting.dispose();
    _commandController.dispose();
    _scrollController.dispose();
    for (final controller in _outputControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _executeCommand(String command) async {
    if (_executing) {
      return;
    }
    _isExecuting.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final result = await _executeBashCommand(command);
      _addCommandResult(command, result);
      _commandController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('命令执行完成'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      _isExecuting.value = false;
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
    if (command.startsWith('ls')) return 'file1.txt\nfile2.txt\nfile3.txt';
    if (command.startsWith('pwd')) return '/home/user/project';
    if (command.startsWith('cd')) return 'Changed directory';
    if (command.startsWith('cat')) return 'File content goes here...\n[EOF]';
    if (command.startsWith('echo')) return command.substring(5);
    if (command.startsWith('mkdir')) return 'Directory created';
    if (command.startsWith('rm')) return 'File/Directory removed';
    if (command.startsWith('clear')) return 'Terminal cleared';
    if (command.startsWith('whoami')) return 'user@hostname';
    if (command.startsWith('date')) return DateTime.now().toString();
    return 'Unknown command: $command';
  }

  void _addCommandResult(String command, String result) {
    setState(() {
      _selectedIndex = _commandHistory.length;
      _commandHistory.add(
        BashCommand(
            command: command, timestamp: DateTime.now(), output: result),
      );
      _outputControllers.add(TextEditingController(text: result));
      if (_selectedIndex == 0) {
        _scrollController.jumpTo(0.0);
      }
    });
    _isExecuting.value = false;
  }

  void _clearTerminal() {
    setState(() {
      for (final controller in _outputControllers) {
        controller.dispose();
      }
      _commandHistory.clear();
      _outputControllers.clear();
      _selectedIndex = -1;
    });
    _isExecuting.value = false;
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
          Expanded(child: _buildTerminalOutput()),
          _buildCommandInput(),
        ],
      ),
    );
  }
}
