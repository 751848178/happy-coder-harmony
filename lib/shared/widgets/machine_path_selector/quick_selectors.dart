part of 'machine_path_selector.dart';

class QuickMachineSelector extends StatelessWidget {
  const QuickMachineSelector({
    super.key,
    required this.selectedMachine,
    required this.onMachineChanged,
    this.compact = false,
  });

  final MachineInfo? selectedMachine;
  final ValueChanged<MachineInfo?> onMachineChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MachineInfo?>(
      initialValue: selectedMachine,
      decoration: InputDecoration(
        labelText: '机器',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: compact,
      ),
      items: [
        ...BuiltInMachines.all,
        const MachineInfo(id: 'add', name: '添加...', host: ''),
      ].map((machine) {
        return DropdownMenuItem<MachineInfo?>(
          value: machine.id == 'add' ? null : machine,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(machine.isLocal ? Icons.computer : Icons.cloud, size: 18),
              const SizedBox(width: 12),
              Text(machine.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (machine) {
        if (machine != null && machine.id != 'add') {
          onMachineChanged(machine);
        }
      },
    );
  }
}

class QuickPathSelector extends StatelessWidget {
  const QuickPathSelector({
    super.key,
    required this.path,
    required this.onPathChanged,
    this.compact = false,
  });

  final String path;
  final ValueChanged<String> onPathChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: path)
        ..selection = const TextSelection.collapsed(offset: 0),
      decoration: InputDecoration(
        labelText: '路径',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: compact,
        prefixIcon: const Icon(Icons.folder, size: 18),
      ),
      onChanged: onPathChanged,
    );
  }
}
