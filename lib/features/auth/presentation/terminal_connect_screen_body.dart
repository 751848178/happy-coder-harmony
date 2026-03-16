part of 'terminal_connect_screen.dart';

Widget _buildTerminalConnectScaffold(_TerminalConnectScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: state._dismissScreen,
      ),
      title: const Text('连接电脑'),
    ),
    body: SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTerminalIntroCard(),
                const SizedBox(height: 20),
                _buildTerminalServerCard(),
                const SizedBox(height: 20),
                if (state._parsedLink == null)
                  _buildTerminalWaitingCard(state)
                else
                  _buildTerminalReadySection(state),
              ],
            ),
          ),
          if (state._showEntrySheet) _buildEntrySheetOverlay(state),
          if (state._isConnecting || state._connectFailureMessage != null)
            _buildStatusOverlay(state),
        ],
      ),
    ),
  );
}

Widget _buildTerminalReadySection(_TerminalConnectScreenState state) {
  return Column(
    children: [
      _buildTerminalParsedLinkCard(state),
      const SizedBox(height: 12),
      if (state._errorMessage != null)
        _buildTerminalMessage(
          message: state._errorMessage!,
          color: AppTheme.errorColor,
        ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: state._isConnecting ? null : state._connectTerminal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '连接电脑',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );
}
