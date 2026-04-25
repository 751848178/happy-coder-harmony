import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../scan_qr_screen.dart';

part 'actions.dart';
part 'parse.dart';
part 'body.dart';
part 'cards.dart';
part 'overlays.dart';
part 'status_overlay.dart';

/// 电脑连接页面
///
/// 使用 happy://terminal?{publicKeyBase64Url} 链接授权终端
class TerminalConnectScreen extends ConsumerStatefulWidget {
  const TerminalConnectScreen({super.key, this.authUrl});

  final String? authUrl;

  @override
  ConsumerState<TerminalConnectScreen> createState() =>
      _TerminalConnectScreenState();
}

class _TerminalConnectScreenState extends ConsumerState<TerminalConnectScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _showEntrySheet = false;
  String? _errorMessage;
  String? _connectFailureMessage;
  String? _publicKeyPreview;
  String? _parsedLink;

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _linkController.addListener(_handleLinkChanged);
    if (widget.authUrl != null && widget.authUrl!.trim().isNotEmpty) {
      _linkController.text = widget.authUrl!.trim();
      _previewLink(showError: false);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _linkController.text.trim().isNotEmpty) {
        return;
      }
      setState(() {
        _showEntrySheet = true;
      });
    });
  }

  @override
  void dispose() {
    _linkController
      ..removeListener(_handleLinkChanged)
      ..dispose();
    super.dispose();
  }

  void _handleLinkChanged() => _handleLinkChangedImpl(this);

  Future<void> _connectTerminal() => _connectTerminalImpl(this);

  Future<void> _startScan() => _startScanImpl(this);

  Future<void> _showSuccessDialogAndExit() =>
      _showSuccessDialogAndExitImpl(this);

  Future<void> _prepareConnectedState() => _prepareConnectedStateImpl(this);

  bool _previewLink({bool showError = true}) =>
      _previewLinkImpl(this, showError: showError);

  void _clearInput() => _clearInputImpl(this);

  void _dismissScreen() => _dismissScreenImpl(this);

  void _openEntrySheet() => _openEntrySheetImpl(this);

  void _closeEntrySheet() => _closeEntrySheetImpl(this);

  void _submitEntrySheet() => _submitEntrySheetImpl(this);

  @override
  Widget build(BuildContext context) => _buildTerminalConnectScaffold(this);
}
