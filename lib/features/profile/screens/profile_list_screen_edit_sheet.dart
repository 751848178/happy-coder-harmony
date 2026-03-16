part of 'profile_list_screen.dart';

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

  final _baseUrlController = TextEditingController();
  final _authTokenController = TextEditingController();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _apiVersionController = TextEditingController();
  final _deploymentNameController = TextEditingController();

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _initializeProfileEditSheet(this, widget.profile);
  }

  @override
  void dispose() {
    _disposeProfileEditSheet(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildProfileEditSheet(this);
}
