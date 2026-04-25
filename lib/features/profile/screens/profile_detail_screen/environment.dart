part of 'profile_detail_screen.dart';

extension _ProfileDetailScreenEnvironment on _ProfileDetailScreenState {
  Widget _buildEnvironmentVariablesSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('环境变量'),
            const SizedBox(height: AppTheme.spacingSm),
            if (_environmentVariables.isEmpty)
              Text(
                '暂无环境变量',
                style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
              ),
            ...List.generate(
              _environmentVariables.length,
              (index) => _buildEnvironmentVariableField(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentVariableField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _nameControllers[index],
              decoration: const InputDecoration(
                labelText: '变量名',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: TextFormField(
              controller: _valueControllers[index],
              decoration: const InputDecoration(
                labelText: '变量值',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          IconButton(
            icon: const Icon(Icons.remove_circle),
            onPressed: () => _removeEnvironmentVariable(index),
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  void _removeEnvironmentVariable(int index) {
    _updateView(() {
      _environmentVariables.removeAt(index);
      _nameControllers.removeAt(index);
      _valueControllers.removeAt(index);
    });
  }
}
