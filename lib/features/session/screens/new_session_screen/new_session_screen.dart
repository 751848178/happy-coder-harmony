import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../presentation/session_detail_navigation.dart';

part 'content.dart';
part 'templates.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({super.key});

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  final List<SessionTemplate> _templates = const [
    SessionTemplate(
      id: 'general',
      name: '通用对话',
      icon: Icons.chat_bubble_outline,
      description: '开始一次新的通用对话',
      color: AppTheme.brandColor,
    ),
    SessionTemplate(
      id: 'code',
      name: '代码开发',
      icon: Icons.code,
      description: '用于代码编写和调试',
      color: AppTheme.infoColor,
    ),
    SessionTemplate(
      id: 'debug',
      name: '问题调试',
      icon: Icons.bug_report_outlined,
      description: '调试和分析代码问题',
      color: AppTheme.warningColor,
    ),
    SessionTemplate(
      id: 'review',
      name: '代码审查',
      icon: Icons.find_in_page,
      description: '审查和改进代码质量',
      color: AppTheme.successColor,
    ),
    SessionTemplate(
      id: 'documentation',
      name: '文档编写',
      icon: Icons.description_outlined,
      description: '生成和编辑项目文档',
      color: AppTheme.neutral700,
    ),
  ];

  String _selectedTag = 'general';
  bool _isCreating = false;

  void _selectTag(String tag) {
    setState(() => _selectedTag = tag);
  }

  void _setCreating(bool value) {
    setState(() => _isCreating = value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('新建会话'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildScrollableContent()),
          _buildFooter(),
        ],
      ),
    );
  }
}
