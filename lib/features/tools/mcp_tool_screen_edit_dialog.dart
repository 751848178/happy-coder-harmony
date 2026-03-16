part of 'mcp_tool_screen.dart';

void _showMcpEditDialog(
  _MCPToolScreenState state, [
  MCPServerConfig? server,
]) {
  final nameController = TextEditingController(text: server?.name ?? '');
  final commandController = TextEditingController(text: server?.command ?? '');
  final argsController =
      TextEditingController(text: server?.args.join(' ') ?? '');
  final envController = TextEditingController(
    text: server?.env.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('\n') ??
        '',
  );

  showDialog<void>(
    context: state.context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        var selectedType = server?.type ?? MCPServerType.stdio;
        return AlertDialog(
          title: Text(server == null ? '添加 MCP 服务器' : '编辑 MCP 服务器'),
          content: _buildMcpEditForm(
            nameController: nameController,
            commandController: commandController,
            argsController: argsController,
            envController: envController,
            selectedType: selectedType,
            onTypeChanged: (type) => setDialogState(() => selectedType = type),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => _saveMcpServer(
                state,
                context,
                existing: server,
                selectedType: selectedType,
                nameController: nameController,
                commandController: commandController,
                argsController: argsController,
                envController: envController,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildMcpEditForm({
  required TextEditingController nameController,
  required TextEditingController commandController,
  required TextEditingController argsController,
  required TextEditingController envController,
  required MCPServerType selectedType,
  required ValueChanged<MCPServerType> onTypeChanged,
}) {
  return SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
              labelText: '名称', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const Text('服务器类型', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<MCPServerType>(
          segments: const [
            ButtonSegment(value: MCPServerType.local, label: Text('本地')),
            ButtonSegment(value: MCPServerType.stdio, label: Text('STDIO')),
            ButtonSegment(value: MCPServerType.sse, label: Text('SSE')),
          ],
          selected: {selectedType},
          onSelectionChanged: (selection) => onTypeChanged(selection.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commandController,
          decoration: const InputDecoration(
            labelText: '命令',
            border: OutlineInputBorder(),
            hintText: '例如: npx, uvx',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: argsController,
          decoration: const InputDecoration(
            labelText: '参数',
            border: OutlineInputBorder(),
            hintText: '空格分隔的参数',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: envController,
          decoration: const InputDecoration(
            labelText: '环境变量（每行一个）',
            border: OutlineInputBorder(),
            hintText: 'KEY=value',
          ),
          maxLines: 3,
        ),
      ],
    ),
  );
}

void _saveMcpServer(
  _MCPToolScreenState state,
  BuildContext dialogContext, {
  required MCPServerType selectedType,
  required TextEditingController nameController,
  required TextEditingController commandController,
  required TextEditingController argsController,
  required TextEditingController envController,
  MCPServerConfig? existing,
}) {
  if (nameController.text.trim().isEmpty) {
    state._showSnackBar('请输入服务器名称', isError: true);
    return;
  }

  final newServer = MCPServerConfig(
    id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: nameController.text.trim(),
    command: commandController.text.trim(),
    args: argsController.text
        .trim()
        .split(' ')
        .where((arg) => arg.isNotEmpty)
        .toList(),
    env: _parseMcpEnv(envController.text),
    type: selectedType,
    status: MCPServerStatus.disconnected,
  );

  state._updateView(() {
    if (existing == null) {
      state._servers.add(newServer);
      return;
    }
    final index =
        state._servers.indexWhere((server) => server.id == existing.id);
    if (index != -1) {
      state._servers[index] = state._servers[index].copyWith(
        name: newServer.name,
        command: newServer.command,
        args: newServer.args,
        env: newServer.env,
        type: newServer.type,
      );
    }
  });
  Navigator.pop(dialogContext);
  state._showSnackBar('MCP 服务器已保存', isError: false);
}

Map<String, String> _parseMcpEnv(String raw) {
  final envMap = <String, String>{};
  for (final line in raw.split('\n')) {
    final parts = line.split('=');
    if (parts.length == 2) {
      envMap[parts[0].trim()] = parts[1].trim();
    }
  }
  return envMap;
}
