part of 'display_settings.dart';

class _AvatarStyleOption extends ConsumerWidget {
  const _AvatarStyleOption();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarStyle = ref.watch(avatarStyleOptionProvider);
    return Card(
      child: ListTile(
        title: const Text('头像样式'),
        subtitle: const Text('选择用户头像显示风格'),
        trailing: DropdownButton<String>(
          value: avatarStyle,
          items: const [
            DropdownMenuItem(value: 'gradient', child: Text('渐变')),
            DropdownMenuItem(value: 'pixelated', child: Text('像素')),
            DropdownMenuItem(value: 'brutalist', child: Text('粗野')),
            DropdownMenuItem(value: 'minimalist', child: Text('极简')),
            DropdownMenuItem(value: 'glass', child: Text('毛玻璃')),
            DropdownMenuItem(value: 'outline', child: Text('轮廓')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(avatarStyleOptionProvider.notifier).state = value;
            }
          },
        ),
      ),
    );
  }
}

class _ShowFlavorIconOption extends StatelessWidget {
  const _ShowFlavorIconOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: showFlavorIconProvider,
      title: '显示 Flavor 图标',
      subtitle: '在会话中显示模型类型图标',
      icon: Icons.psychology,
    );
  }
}
