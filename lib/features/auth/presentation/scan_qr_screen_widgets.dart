part of 'scan_qr_screen.dart';

Widget _buildScanQrFrameOverlay() {
  return Container(
    decoration: BoxDecoration(
      border:
          Border.all(color: Colors.black.withValues(alpha: 0.35), width: 52),
    ),
    child: Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        ),
      ),
    ),
  );
}

Widget _buildScanQrFooter(_ScanQrScreenState state) {
  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              state.widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          if (!HarmonyBridge.isHarmonyOS)
            FilledButton.icon(
              onPressed: state._toggleTorch,
              icon: Icon(
                state._torchEnabled
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
              ),
              label: Text(state._torchEnabled ? '关闭补光' : '打开补光'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
            )
          else if (state._useHarmonyScanner)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    state._scannerMessage ?? '正在等待扫码结果…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state._retryHarmonyScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('重新扫码'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Widget _buildHarmonyScannerState(_ScanQrScreenState state) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScanQrPlaceholder(
            icon: Icons.qr_code_scanner_rounded,
            borderColor: Colors.white.withValues(alpha: 0.9),
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 24),
          Text(
            state._scannerMessage ?? '请使用鸿蒙原生扫码能力扫描二维码',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHarmonyUnavailableState(_ScanQrScreenState state) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScanQrPlaceholder(
            icon: Icons.link_rounded,
            borderColor: Colors.white.withValues(alpha: 0.16),
            fillColor: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 24),
          Text(
            state._scannerMessage ?? '当前设备还没有接通鸿蒙原生扫码能力，请先返回上一页粘贴链接。',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    ),
  );
}

Widget _buildScanQrPlaceholder({
  required IconData icon,
  required Color borderColor,
  required Color fillColor,
}) {
  return Container(
    width: 220,
    height: 220,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: borderColor, width: 2),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: fillColor,
            ),
          ),
        ),
        Center(child: Icon(icon, color: Colors.white, size: 72)),
      ],
    ),
  );
}
