import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 路径选择页
class SessionPathPickerScreen extends StatefulWidget {
  const SessionPathPickerScreen({
    super.key,
    this.machineId,
    this.initialPath,
  });

  final String? machineId;
  final String? initialPath;

  @override
  State<SessionPathPickerScreen> createState() => _SessionPathPickerScreenState();
}

class _SessionPathPickerScreenState extends State<SessionPathPickerScreen> {
  late final TextEditingController _controller;

  static const List<String> _commonPaths = [
    '~',
    '~/Desktop',
    '~/Documents',
    '~/Downloads',
    '~/Projects',
    '/tmp',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPath ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final path = _controller.text.trim();
    Navigator.of(context).pop(path.isEmpty ? '~' : path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('选择路径'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('完成'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.machineId != null && widget.machineId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '当前机器: ${widget.machineId}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                ),
              ),
            ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '输入工作目录',
              prefixIcon: const Icon(Icons.folder_open),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 20),
          const Text(
            '常用路径',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonPaths.map((path) {
              final isSelected = _controller.text.trim() == path;
              return ChoiceChip(
                label: Text(path),
                selected: isSelected,
                onSelected: (_) => setState(() => _controller.text = path),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
