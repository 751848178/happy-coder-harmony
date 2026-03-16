part of 'scan_qr_screen.dart';

Widget _buildScanQrScaffold(_ScanQrScreenState state) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(state.widget.title),
    ),
    body: Stack(
      children: [
        Positioned.fill(child: _buildScanQrBody(state)),
        Positioned.fill(
            child: IgnorePointer(child: _buildScanQrFrameOverlay())),
        Align(
            alignment: Alignment.bottomCenter,
            child: _buildScanQrFooter(state)),
      ],
    ),
  );
}

Widget _buildScanQrBody(_ScanQrScreenState state) {
  if (state._isCheckingScanner) {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
  if (!HarmonyBridge.isHarmonyOS) {
    return MobileScanner(
        controller: state._controller, onDetect: state._handleDetection);
  }
  return state._useHarmonyScanner
      ? _buildHarmonyScannerState(state)
      : _buildHarmonyUnavailableState(state);
}
