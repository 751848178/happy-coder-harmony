import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';

/// 新建会话屏幕
class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({super.key});

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  String _selectedTag = 'general';
  bool _isCreating = false;

  final List<SessionTemplate> _templates = [
    const SessionTemplate(
      id: 'general',
      name: '通用对话',
      icon: Icons.chat_bubble_outline,
      description: '开始一次新的通用对话',
      color: AppTheme.brandColor,
    ),
    const SessionTemplate(
      id: 'code',
      name: '代码开发',
      icon: Icons.code,
      description: '用于代码编写和调试',
      color: AppTheme.infoColor,
    ),
    const SessionTemplate(
      id: 'debug',
      name: '问题调试',
      icon: Icons.bug_report_outlined,
      description: '调试和分析代码问题',
      color: AppTheme.warningColor,
    ),
    const SessionTemplate(
      id: 'review',
      name: '代码审查',
      icon: Icons.find_in_page,
      description: '审查和改进代码质量',
      color: AppTheme.successColor,
    ),
    const SessionTemplate(
      id: 'documentation',
      name: '文档编写',
      icon: Icons.description_outlined,
      description: '生成和编辑项目文档',
      color: AppTheme.neutral700,
    ),
  ];

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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题输入
                  const Text(
                    '会话标题',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '输入会话标题（可选）',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingMd,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // 会话类型选择
                  const Text(
                    '选择会话类型',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: _templates.map((template) {
                      return _TemplateCard(
                        template: template,
                        isSelected: _selectedTag == template.id,
                        onTap: () => setState(() => _selectedTag = template.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // 工作路径（可选）
                  const Text(
                    '工作路径（可选）',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      hintText: '输入项目工作路径',
                      prefixIcon: const Icon(Icons.folder_outlined),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingMd,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // 描述（可选）
                  const Text(
                    '会话描述（可选）',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '添加会话描述或初始提示',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingMd,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.neutral200),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('创建会话'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createSession() async {
    setState(() => _isCreating = true);

    try {
      final path = _pathController.text.trim();
      final description = _descriptionController.text.trim();

      final sessionId = await ref.read(sessionStateProvider.notifier).createSession(
            title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            tag: _selectedTag,
            path: path.isNotEmpty ? path : null,
            metadata: description.isNotEmpty ? {'description': description} : null,
          );

      if (sessionId != null && mounted) {
        context.push(AppRoutes.sessionDetail(sessionId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建会话失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

/// 会话模板
class SessionTemplate {
  const SessionTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color color;
}

/// 模板卡片
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final SessionTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2 - 8,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? template.color.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? template.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(template.icon, color: template.color, size: 28),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? template.color : AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
