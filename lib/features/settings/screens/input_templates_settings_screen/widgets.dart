import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TemplateInfoCard extends StatelessWidget {
  const TemplateInfoCard({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.brandColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '会话输入框里输入 ^，就会弹出这些快捷模板',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '内置模板可以直接用；自定义模板可以在这里新增、编辑和删除。',
            style: TextStyle(fontSize: 13, color: AppTheme.neutral700),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建自定义模板'),
          ),
        ],
      ),
    );
  }
}

class TemplateSectionTitle extends StatelessWidget {
  const TemplateSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.neutral700,
      ),
    );
  }
}

class TemplateEmptyCard extends StatelessWidget {
  const TemplateEmptyCard({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.note_add_outlined,
            size: 28,
            color: AppTheme.neutral500,
          ),
          const SizedBox(height: 10),
          const Text(
            '还没有自定义模板',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '可以把常用提示词存成模板，输入 ^ 就能快速插入。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('创建模板'),
          ),
        ],
      ),
    );
  }
}

class TemplateTile extends StatelessWidget {
  const TemplateTile({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
    this.tag,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String content;
  final VoidCallback onTap;
  final String? tag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.brandColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
