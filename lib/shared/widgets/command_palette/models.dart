part of 'command_palette.dart';

enum CommandType {
  navigation,
  action,
  search,
  settings,
}

class CommandItem {
  const CommandItem({
    required this.id,
    required this.label,
    required this.icon,
    this.keywords = const [],
    this.type = CommandType.action,
    this.route,
    this.description = '',
    this.action,
    this.subcommands,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<String> keywords;
  final CommandType type;
  final String? route;
  final VoidCallback? action;
  final List<CommandItem>? subcommands;
}
