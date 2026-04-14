import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/network/local_proxy_server.dart';
import '../../../core/network/proxy_state.dart';
import '../../../core/theme/app_theme.dart';

/// A screen that loads a PC localhost service through the local proxy.
///
/// The proxy must already be started (via [ProxyNotifier.start]) before
/// navigating to this screen. The WebView loads [LocalProxyServer.proxyUrl]
/// plus an optional [initialPath].
class WebViewScreen extends ConsumerStatefulWidget {
  final String? initialPath;
  final String? title;

  const WebViewScreen({super.key, this.initialPath, this.title});

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  late final WebViewController _controller;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  void _setupController() {
    final proxy = LocalProxyServer.instance;
    final proxyUrl = proxy.proxyUrl;
    if (proxyUrl.isEmpty) {
      _error = 'Proxy not started';
      return;
    }

    final initialUrl =
        proxyUrl + (widget.initialPath ?? '/');
    _currentUrl = initialUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            _canGoBack = await _controller.canGoBack();
            _canGoForward = await _controller.canGoForward();
            final url = await _controller.currentUrl();
            if (url != null && mounted) {
              setState(() => _currentUrl = url);
            }
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _error = 'Error ${error.errorCode}: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    final proxyState = ref.watch(proxyStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? 'Local Service',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              _displayUrl,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.neutral500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: _canGoBack ? () => _controller.goBack() : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 20),
            onPressed: _canGoForward ? () => _controller.goForward() : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: _buildBody(proxyState),
    );
  }

  Widget _buildBody(ProxyState proxyState) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.neutral600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _controller.reload();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!proxyState.isRunning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppTheme.neutral400),
            SizedBox(height: 16),
            Text('Proxy not running', style: TextStyle(color: AppTheme.neutral600)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const LinearProgressIndicator(
            backgroundColor: AppTheme.neutral200,
          ),
      ],
    );
  }

  String get _displayUrl {
    // Show the path relative to the proxy for brevity.
    final proxyUrl = LocalProxyServer.instance.proxyUrl;
    if (_currentUrl.startsWith(proxyUrl)) {
      return _currentUrl.substring(proxyUrl.length);
    }
    return _currentUrl;
  }
}
