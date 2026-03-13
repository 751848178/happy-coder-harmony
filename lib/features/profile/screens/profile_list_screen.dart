import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/profile_models.dart';
import '../domain/profile_state.dart';
import '../data/profile_repository.dart';
import '../presentation/profile_notifier.dart';
import '../widgets/model_selector.dart';

/// Profile state provider
final profileStateProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ProfileRepository.instance);
});

/// Profile list screen for managing AI backend profiles
class ProfileListScreen extends ConsumerStatefulWidget {
  const ProfileListScreen({super.key});

  @override
  ConsumerState<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends ConsumerState<ProfileListScreen> {
  @override
  void initState() {
    super.initState();
    // Load profiles on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileStateProvider.notifier).loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('AI 配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateProfileDialog(),
            tooltip: '创建配置',
          ),
        ],
      ),
      body: _buildBody(profileState),
    );
  }

  Widget _buildBody(ProfileState profileState) {
    if (profileState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileState.error != null) {
      return _buildErrorView(profileState.error!);
    }

    final profiles = profileState.profiles;
    String? activeProfileId;
    if (profileState is ProfileLoaded) {
      activeProfileId = profileState.activeProfileId;
    }

    if (profiles.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final isActive = profile.id == activeProfileId;

        return _ProfileCard(
          profile: profile,
          isActive: isActive,
          onTap: () => _showProfileOptions(profile),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '暂无配置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '创建您的第一个 AI 配置',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: () => _showCreateProfileDialog(),
            icon: const Icon(Icons.add),
            label: const Text('创建配置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton(
            onPressed: () {
              ref.read(profileStateProvider.notifier).loadProfiles();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showCreateProfileDialog() {
    _showProfileEditDialog();
  }

  void _showProfileOptions(AIProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Profile info
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
                  child: Icon(
                    _getProviderIcon(profile),
                    color: AppTheme.brandColor,
                  ),
                ),
                title: Text(
                  profile.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: profile.description != null
                    ? Text(profile.description!)
                    : Text(profile.providerDisplayName ?? '未知'),
              ),
              const Divider(height: 1),
              // Actions
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileEditDialog(profile: profile);
                },
              ),
              if (!profile.isBuiltIn)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('克隆'),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(profileStateProvider.notifier).cloneProfile(profile);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('配置已克隆'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除'),
                textColor: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(profile);
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileEditDialog({AIProfile? profile}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileEditSheet(profile: profile),
    );

    if (result != null && mounted) {
      if (profile == null) {
        // Create new profile
        await ref.read(profileStateProvider.notifier).createProfile(
              _createProfileFromEditResult(result),
            );
      } else {
        // Update existing profile
        await ref.read(profileStateProvider.notifier).updateProfile(
              _updateProfileFromEditResult(profile, result),
            );
      }
    }
  }

  void _showDeleteConfirmation(AIProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确认要删除 "${profile.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profileStateProvider.notifier).deleteProfile(profile.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('配置已删除'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
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

  AIProfile _createProfileFromEditResult(Map<String, dynamic> result) {
    final id = const Uuid().v4();
    String? providerType = result['providerType'] as String?;
    String? name = result['name'] as String?;
    String? description = result['description'] as String?;

    // Set default configs based on provider
    AnthropicConfig? anthropicConfig;
    OpenAIConfig? openaiConfig;
    AzureOpenAIConfig? azureOpenAIConfig;
    TogetherAIConfig? togetherAIConfig;

    switch (providerType) {
      case 'anthropic':
        name ??= 'Anthropic';
        anthropicConfig = AnthropicConfig(
          baseUrl: result['baseUrl'] as String?,
          authToken: result['authToken'] as String?,
          model: result['model'] as String?,
        );
        break;
      case 'openai':
        name ??= 'OpenAI';
        openaiConfig = OpenAIConfig(
          apiKey: result['apiKey'] as String?,
          baseUrl: result['baseUrl'] as String?,
          model: result['model'] as String?,
        );
        break;
      case 'azure':
        name ??= 'Azure OpenAI';
        azureOpenAIConfig = AzureOpenAIConfig(
          apiKey: result['apiKey'] as String?,
          endpoint: result['endpoint'] as String?,
          apiVersion: result['apiVersion'] as String?,
          deploymentName: result['deploymentName'] as String?,
        );
        break;
      case 'together':
        name ??= 'Together AI';
        togetherAIConfig = TogetherAIConfig(
          apiKey: result['apiKey'] as String?,
          model: result['model'] as String?,
        );
        break;
    }

    // Ensure name is not null
    name ??= 'AI Profile';

    return AIProfile(
      id: id,
      name: name,
      description: description,
      anthropicConfig: anthropicConfig,
      openaiConfig: openaiConfig,
      azureOpenAIConfig: azureOpenAIConfig,
      togetherAIConfig: togetherAIConfig,
      defaultPermissionMode: result['permissionMode'] as PermissionMode?,
      defaultSessionType: result['sessionType'] as SessionType?,
      compatibility: const ProfileCompatibility(),
    );
  }

  AIProfile _updateProfileFromEditResult(
      AIProfile profile, Map<String, dynamic> result) {
    String? providerType = result['providerType'] as String?;
    String name = result['name'] as String? ?? profile.name;
    String? description = result['description'] as String?;

    // Update configs based on provider
    AnthropicConfig? anthropicConfig = profile.anthropicConfig;
    OpenAIConfig? openaiConfig = profile.openaiConfig;
    AzureOpenAIConfig? azureOpenAIConfig = profile.azureOpenAIConfig;
    TogetherAIConfig? togetherAIConfig = profile.togetherAIConfig;

    switch (providerType) {
      case 'anthropic':
        anthropicConfig = anthropicConfig?.copyWith(
          baseUrl: result['baseUrl'] as String?,
          authToken: result['authToken'] as String?,
          model: result['model'] as String?,
        );
        break;
      case 'openai':
        openaiConfig = openaiConfig?.copyWith(
          apiKey: result['apiKey'] as String?,
          baseUrl: result['baseUrl'] as String?,
          model: result['model'] as String?,
        );
        break;
      case 'azure':
        azureOpenAIConfig = azureOpenAIConfig?.copyWith(
          apiKey: result['apiKey'] as String?,
          endpoint: result['endpoint'] as String?,
          apiVersion: result['apiVersion'] as String?,
          deploymentName: result['deploymentName'] as String?,
        );
        break;
      case 'together':
        togetherAIConfig = togetherAIConfig?.copyWith(
          apiKey: result['apiKey'] as String?,
          model: result['model'] as String?,
        );
        break;
    }

    return profile.copyWith(
      name: name,
      description: description,
      anthropicConfig: anthropicConfig,
      openaiConfig: openaiConfig,
      azureOpenAIConfig: azureOpenAIConfig,
      togetherAIConfig: togetherAIConfig,
      defaultPermissionMode: result['permissionMode'] as PermissionMode?,
      defaultSessionType: result['sessionType'] as SessionType?,
    );
  }

  IconData _getProviderIcon(AIProfile profile) {
    switch (profile.providerType) {
      case 'anthropic':
        return Icons.psychology;
      case 'openai':
        return Icons.smart_toy;
      case 'azure':
        return Icons.cloud;
      case 'together':
        return Icons.auto_awesome;
      default:
        return Icons.settings;
    }
  }
}

/// Profile card widget
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final AIProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: isActive
            ? BorderSide(color: AppTheme.brandColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  _getProviderIcon(profile),
                  color: AppTheme.brandColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        if (profile.isBuiltIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '内置',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.infoColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '当前',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (profile.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          profile.providerDisplayName ?? '未知',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral500,
                          ),
                        ),
                        if (profile.defaultPermissionMode != null) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              profile.defaultPermissionMode!.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Icon(
                Icons.chevron_right,
                color: AppTheme.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProviderIcon(AIProfile profile) {
    switch (profile.providerType) {
      case 'anthropic':
        return Icons.psychology;
      case 'openai':
        return Icons.smart_toy;
      case 'azure':
        return Icons.cloud;
      case 'together':
        return Icons.auto_awesome;
      default:
        return Icons.settings;
    }
  }
}

/// Profile edit sheet
class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({this.profile});

  final AIProfile? profile;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String _providerType = 'anthropic';
  PermissionMode? _permissionMode;
  SessionType? _sessionType;
  ModelOption? _selectedModel;

  // Anthropic config
  final _baseUrlController = TextEditingController();
  final _authTokenController = TextEditingController();
  final _modelController = TextEditingController();

  // OpenAI/Azure config
  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _apiVersionController = TextEditingController();
  final _deploymentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final profile = widget.profile;

    if (profile != null) {
      _nameController = TextEditingController(text: profile.name);
      _descriptionController =
          TextEditingController(text: profile.description ?? '');

      // Determine provider type
      String? modelValue;
      if (profile.anthropicConfig != null) {
        _providerType = 'anthropic';
        _baseUrlController.text = profile.anthropicConfig!.baseUrl ?? '';
        _authTokenController.text = profile.anthropicConfig!.authToken ?? '';
        modelValue = profile.anthropicConfig!.model;
        _modelController.text = modelValue ?? '';
      } else if (profile.openaiConfig != null) {
        _providerType = 'openai';
        _apiKeyController.text = profile.openaiConfig!.apiKey ?? '';
        _baseUrlController.text = profile.openaiConfig!.baseUrl ?? '';
        modelValue = profile.openaiConfig!.model;
        _modelController.text = modelValue ?? '';
      } else if (profile.azureOpenAIConfig != null) {
        _providerType = 'azure';
        _apiKeyController.text = profile.azureOpenAIConfig!.apiKey ?? '';
        _endpointController.text = profile.azureOpenAIConfig!.endpoint ?? '';
        _apiVersionController.text = profile.azureOpenAIConfig!.apiVersion ?? '';
        _deploymentNameController.text =
            profile.azureOpenAIConfig!.deploymentName ?? '';
        // Azure uses deploymentName instead of model
        modelValue = profile.azureOpenAIConfig!.deploymentName;
      } else if (profile.togetherAIConfig != null) {
        _providerType = 'together';
        _apiKeyController.text = profile.togetherAIConfig!.apiKey ?? '';
        modelValue = profile.togetherAIConfig!.model;
        _modelController.text = modelValue ?? '';
      }

      // Set selected model from profile
      if (modelValue != null) {
        final options = ModelOption.getOptionsForProvider(_providerType);
        _selectedModel = options.cast<ModelOption?>().firstWhere(
          (option) => option?.model == modelValue,
          orElse: () => null,
        );
      }

      _permissionMode = profile.defaultPermissionMode;
      _sessionType = profile.defaultSessionType;
    } else {
      _nameController = TextEditingController(text: '');
      _descriptionController = TextEditingController(text: '');
      _permissionMode = PermissionMode.defaultMode;
      _sessionType = SessionType.simple;
      // Set default model
      final options = ModelOption.getOptionsForProvider(_providerType);
      if (options.isNotEmpty) {
        _selectedModel = options.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _baseUrlController.dispose();
    _authTokenController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    _endpointController.dispose();
    _apiVersionController.dispose();
    _deploymentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Row(
                children: [
                  Text(
                    widget.profile == null ? '创建配置' : '编辑配置',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                  ),
                  children: [
                    // Basic info
                    _buildSectionHeader('基本信息'),
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
                    const SizedBox(height: AppTheme.spacingLg),

                    // Provider selection
                    if (widget.profile == null) ...[
                      _buildSectionHeader('AI 提供商'),
                      DropdownButtonFormField<String>(
                        value: _providerType,
                        decoration: const InputDecoration(
                          labelText: '选择提供商',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'anthropic',
                            child: Row(
                              children: [
                                Icon(Icons.psychology, size: 20),
                                SizedBox(width: 12),
                                Text('Anthropic (Claude)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'openai',
                            child: Row(
                              children: [
                                Icon(Icons.smart_toy, size: 20),
                                SizedBox(width: 12),
                                Text('OpenAI (GPT)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'azure',
                            child: Row(
                              children: [
                                Icon(Icons.cloud, size: 20),
                                SizedBox(width: 12),
                                Text('Azure OpenAI'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'together',
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 20),
                                SizedBox(width: 12),
                                Text('Together AI'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _providerType = value!;
                            // Reset selected model when provider changes
                            final options = ModelOption.getOptionsForProvider(_providerType);
                            if (options.isNotEmpty) {
                              _selectedModel = options.first;
                            } else {
                              _selectedModel = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // Provider-specific config
                    _buildProviderConfig(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Default settings
                    _buildSectionHeader('默认设置'),
                    DropdownButtonFormField<PermissionMode>(
                      value: _permissionMode,
                      decoration: const InputDecoration(
                        labelText: '权限模式',
                        border: OutlineInputBorder(),
                      ),
                      items: PermissionMode.values
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _permissionMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    DropdownButtonFormField<SessionType>(
                      value: _sessionType,
                      decoration: const InputDecoration(
                        labelText: '会话类型',
                        border: OutlineInputBorder(),
                      ),
                      items: SessionType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _sessionType = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
            // Save button
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.profile == null ? '创建' : '保存',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral600,
        ),
      ),
    );
  }

  Widget _buildProviderConfig() {
    switch (_providerType) {
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
    final options = ModelOption.getOptionsForProvider('anthropic');

    return Column(
      children: [
        _buildSectionHeader('Anthropic 配置'),
        TextFormField(
          controller: _authTokenController,
          decoration: const InputDecoration(
            labelText: 'API Token',
            hintText: 'sk-ant-...',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _baseUrlController,
          decoration: const InputDecoration(
            labelText: 'Base URL（可选）',
            hintText: 'https://api.anthropic.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildSectionHeader('模型选择'),
        ModelSelector(
          options: options,
          selectedOption: _selectedModel,
          onChanged: (option) {
            setState(() {
              _selectedModel = option;
              _modelController.text = option.model ?? '';
            });
          },
        ),
        if (_selectedModel != null && _selectedModel!.maxTokens != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: ContextSizeDisplay(
              maxTokens: _selectedModel!.maxTokens!,
              contextWindow: _selectedModel!.contextWindow ?? '',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpenAIConfig() {
    final options = ModelOption.getOptionsForProvider('openai');

    return Column(
      children: [
        _buildSectionHeader('OpenAI 配置'),
        TextFormField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-...',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _baseUrlController,
          decoration: const InputDecoration(
            labelText: 'Base URL（可选）',
            hintText: 'https://api.openai.com/v1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildSectionHeader('模型选择'),
        ModelSelector(
          options: options,
          selectedOption: _selectedModel,
          onChanged: (option) {
            setState(() {
              _selectedModel = option;
              _modelController.text = option.model ?? '';
            });
          },
        ),
        if (_selectedModel != null && _selectedModel!.maxTokens != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: ContextSizeDisplay(
              maxTokens: _selectedModel!.maxTokens!,
              contextWindow: _selectedModel!.contextWindow ?? '',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAzureConfig() {
    final options = ModelOption.getOptionsForProvider('azure');

    return Column(
      children: [
        _buildSectionHeader('Azure OpenAI 配置'),
        TextFormField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _endpointController,
          decoration: const InputDecoration(
            labelText: 'Endpoint',
            hintText: 'https://your-resource.openai.azure.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _apiVersionController,
          decoration: const InputDecoration(
            labelText: 'API Version',
            hintText: '2024-02-15-preview',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _deploymentNameController,
          decoration: const InputDecoration(
            labelText: 'Deployment Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildSectionHeader('模型选择'),
        ModelSelector(
          options: options,
          selectedOption: _selectedModel,
          onChanged: (option) {
            setState(() {
              _selectedModel = option;
              _modelController.text = option.model ?? '';
            });
          },
        ),
        if (_selectedModel != null && _selectedModel!.maxTokens != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: ContextSizeDisplay(
              maxTokens: _selectedModel!.maxTokens!,
              contextWindow: _selectedModel!.contextWindow ?? '',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTogetherConfig() {
    final options = ModelOption.getOptionsForProvider('together');

    return Column(
      children: [
        _buildSectionHeader('Together AI 配置'),
        TextFormField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildSectionHeader('模型选择'),
        ModelSelector(
          options: options,
          selectedOption: _selectedModel,
          onChanged: (option) {
            setState(() {
              _selectedModel = option;
              _modelController.text = option.model ?? '';
            });
          },
        ),
        if (_selectedModel != null && _selectedModel!.maxTokens != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: ContextSizeDisplay(
              maxTokens: _selectedModel!.maxTokens!,
              contextWindow: _selectedModel!.contextWindow ?? '',
            ),
          ),
        ],
      ],
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'providerType': _providerType,
      'permissionMode': _permissionMode,
      'sessionType': _sessionType,
    };

    // Add provider-specific fields
    switch (_providerType) {
      case 'anthropic':
        result['baseUrl'] = _baseUrlController.text.trim();
        result['authToken'] = _authTokenController.text.trim();
        result['model'] = _modelController.text.trim();
        break;
      case 'openai':
        result['baseUrl'] = _baseUrlController.text.trim();
        result['apiKey'] = _apiKeyController.text.trim();
        result['model'] = _modelController.text.trim();
        break;
      case 'azure':
        result['apiKey'] = _apiKeyController.text.trim();
        result['endpoint'] = _endpointController.text.trim();
        result['apiVersion'] = _apiVersionController.text.trim();
        result['deploymentName'] = _deploymentNameController.text.trim();
        break;
      case 'together':
        result['apiKey'] = _apiKeyController.text.trim();
        result['model'] = _modelController.text.trim();
        break;
    }

    Navigator.pop(context, result);
  }
}
