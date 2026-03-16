part of 'machine_path_selector.dart';

extension _MachinePathSelectorControls on _MachinePathSelectorState {
  void _showAddMachineDialog() {
    final nameController = TextEditingController();
    final hostController = TextEditingController();
    final sshKeyController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加远程机器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  border: OutlineInputBorder(),
                  hintText: 'user@host 或 host:port',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sshKeyController,
                decoration: const InputDecoration(
                  labelText: 'SSH 密钥（可选）',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  hostController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
