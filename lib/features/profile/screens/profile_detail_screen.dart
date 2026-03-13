import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/profile_models.dart';
import '../domain/profile_state.dart';
import 'profile_list_screen.dart';

/// Profile Detail Screen
///
/// Displays detailed profile configuration with environment variables
class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Environment variables
  final List<EnvironmentVariable> _environmentVariables = [];
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _valueControllers = [];

  AIProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profileState = ref.read(profileStateProvider);
      if (profileState is ProfileLoaded) {
        final profile = profileState.profiles.firstWhereOrNull(
          (p) => p.id == widget.profileId,
        );

        if (profile != null) {
          setState(() {
            _profile = profile;
            _nameController.text = profile.name;
            _descriptionController.text = profile.description ?? '';

            // Load environment variables
            _environmentVariables.clear();
            _nameControllers.clear();
            _valueControllers.clear();

            for (final envVar in profile.environmentVariables) {
              _environmentVariables.add(EnvironmentVariable(
                name: envVar.name,
                value: envVar.value,
              ));
              _nameControllers.add(TextEditingController(text: envVar.name));
              _valueControllers.add(TextEditingController(text: envVar.value));
            }

            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载配置失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profileState = ref.read(profileStateProvider);
      if (profileState is ProfileLoaded && _profile != null) {
        final updatedProfile = _profile!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          environmentVariables: _environmentVariables,
        );

        await ref.read(profileStateProvider.notifier).updateProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('配置已保存'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);
    final profiles = profileState is ProfileLoaded
        ? profileState.profiles
        : <AIProfile>[];

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(_profile?.name ?? '配置详情'),
        actions: [
          if (!_isLoading && !_isSaving) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Allow editing custom profiles only
                if (_profile != null && !_profile!.isBuiltIn) {
                  _showEditDialog();
                }
              },
              tooltip: '编辑',
            ),
          ],
        ],
      ),
      body: _isLoading || _profile == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(profiles),
    );
  }

  Widget _buildBody(List<AIProfile> profiles) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: AppTheme.spacingLg),
        _buildProviderConfigSection(),
        const SizedBox(height: AppTheme.spacingLg),
        _buildEnvironmentVariablesSection(),
        const SizedBox(height: AppTheme.spacingXl),
        if (!_profile!.isBuiltIn) ...[
          _buildDangerSection(),
        ],
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    final providerType = _profile!.providerType;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('基本信息'),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入名称';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (providerType != null) _buildProviderInfo(providerType),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfo(String providerType) {
    String providerName;
    IconData providerIcon;

    switch (providerType) {
      case 'anthropic':
        providerName = 'Anthropic (Claude)';
        providerIcon = Icons.psychology;
        break;
      case 'openai':
        providerName = 'OpenAI (GPT)';
        providerIcon = Icons.smart_toy;
        break;
      case 'azure':
        providerName = 'Azure OpenAI';
        providerIcon = Icons.cloud;
        break;
      case 'together':
        providerName = 'Together AI';
        providerIcon = Icons.auto_awesome;
        break;
      default:
        providerName = '未知';
        providerIcon = Icons.settings;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(providerIcon, color: AppTheme.brandColor, size: 20),
          const SizedBox(width: 12),
          Text(
            providerName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_profile!.isBuiltIn) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '内置',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.infoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderConfigSection() {
    final providerType = _profile!.providerType;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('${_profile!.providerDisplayName ?? 'AI'} 配置'),
            const SizedBox(height: AppTheme.spacingSm),
            if (providerType != null) _buildProviderSpecificConfig(providerType),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSpecificConfig(String providerType) {
    switch (providerType) {
      case 'anthropic':
        return _buildAnthropicConfig();
      case 'openai':
        return _buildOpenAIConfig();
      case 'azure':
        return _buildAzureConfig();
      case 'together':
        return _buildTogetherConfig();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAnthropicConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'API Token',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          obscureText: true,
          controller: TextEditingController(
            text: _profile!.anthropicConfig?.authToken ?? '',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Base URL（可选）',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          controller: TextEditingController(
            text: _profile!.anthropicConfig?.baseUrl ?? '',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          '当前模型: ${_profile!.anthropicConfig?.model ?? '默认'}',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildOpenAIConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          obscureText: true,
          controller: TextEditingController(
            text: _profile!.openaiConfig?.apiKey ?? '',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Base URL（可选）',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          controller: TextEditingController(
            text: _profile!.openaiConfig?.baseUrl ?? '',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          '当前模型: ${_profile!.openaiConfig?.model ?? '默认'}',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildAzureConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          obscureText: true,
          controller: TextEditingController(
            text: _profile!.azureOpenAIConfig?.apiKey ?? '',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Endpoint',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          controller: TextEditingController(
            text: _profile!.azureOpenAIConfig?.endpoint ?? '',
          ),
        ),
      ],
    );
  }

  Widget _buildTogetherConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          obscureText: true,
          controller: TextEditingController(
            text: _profile!.togetherAIConfig?.apiKey ?? '',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          '当前模型: ${_profile!.togetherAIConfig?.model ?? '默认'}',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

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
            if (_environmentVariables.isEmpty) ...[
              Text(
                '暂无环境变量',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                ),
              ),
            ],
            ..._buildEnvironmentVariableFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnvironmentVariableFields() {
    return List.generate(
      _environmentVariables.length,
      (index) => _buildEnvironmentVariableField(index),
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
    setState(() {
      _environmentVariables.removeAt(index);
      _nameControllers.removeAt(index);
      _valueControllers.removeAt(index);
    });
  }

  void _addEnvironmentVariable() {
    setState(() {
      _environmentVariables.add(
        const EnvironmentVariable(name: '', value: ''),
      );
      _nameControllers.add(TextEditingController());
      _valueControllers.add(TextEditingController());
    });
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑配置'),
        content: const Text('此功能将在后续版本中开放'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('操作'),
            const SizedBox(height: AppTheme.spacingSm),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('删除配置'),
              onPressed: () => _showDeleteConfirmation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确认要删除 "${_profile!.name}" 配置吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProfile();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfile() async {
    try {
      await ref.read(profileStateProvider.notifier).deleteProfile(widget.profileId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('配置已删除'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }
}
