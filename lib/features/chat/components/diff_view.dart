import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

part 'diff_view_body.dart';
part 'diff_view_models.dart';

class DiffView extends StatefulWidget {
  const DiffView({
    super.key,
    required this.originalContent,
    required this.modifiedContent,
    this.filename = 'untitled',
  });

  final String originalContent;
  final String modifiedContent;
  final String filename;

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  bool _showLineNumbers = true;
  bool _wrapLines = false;

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  @override
  Widget build(BuildContext context) => _buildDiffViewScaffold(this);
}
