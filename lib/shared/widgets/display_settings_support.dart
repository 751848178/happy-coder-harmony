part of 'display_settings.dart';

class _DisplaySectionHeader extends StatelessWidget {
  const _DisplaySectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DisplayToggleOption extends ConsumerWidget {
  const _DisplayToggleOption({
    required this.provider,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final StateProvider<bool> provider;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: (next) => ref.read(provider.notifier).state = next,
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: AppTheme.neutral500),
      ),
    );
  }
}
