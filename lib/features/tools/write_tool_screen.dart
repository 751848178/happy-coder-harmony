import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

part 'write_tool_actions.dart';
part 'write_tool_content.dart';
part 'write_tool_dialogs.dart';
part 'write_tool_sections.dart';

class WriteToolScreen extends ConsumerStatefulWidget {
  const WriteToolScreen({super.key});

  @override
  ConsumerState<WriteToolScreen> createState() => _WriteToolScreenState();
}

class _WriteToolScreenState extends ConsumerState<WriteToolScreen> {
  final _pathController = TextEditingController();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isWriting = false;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _pathController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateState(VoidCallback update) {
    setState(update);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasUnsavedChanges) {
          return;
        }
        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildScaffold(),
    );
  }
}
