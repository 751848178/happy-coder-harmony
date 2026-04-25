import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../encryption/domain/crypto_service.dart';

part 'actions.dart';
part 'support.dart';
part 'views.dart';

class LinkAccountScreen extends ConsumerStatefulWidget {
  const LinkAccountScreen({super.key, required this.authUrl});

  final String? authUrl;

  @override
  ConsumerState<LinkAccountScreen> createState() => _LinkAccountScreenState();
}

class _LinkAccountScreenState extends ConsumerState<LinkAccountScreen> {
  String? _publicKey;
  String? _publicKeyShort;
  bool _isProcessing = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processAuthUrl();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _processAuthUrl() => _processLinkAccountUrl(this);

  Future<void> _approveLink() => _approveLinkAccount(this);

  void _cancelLink() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) => _buildLinkAccountView(this);
}
