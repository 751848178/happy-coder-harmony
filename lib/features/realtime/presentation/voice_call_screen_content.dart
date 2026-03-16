part of 'voice_call_screen.dart';

extension _VoiceCallScreenContent on _VoiceCallScreenState {
  Widget _buildAudioVisualization(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AudioWavePainter(_audioLevels),
      ),
    );
  }

  Widget _buildTopInfo(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandColor.withValues(alpha: 0.2),
                  border: Border.fromBorderSide(
                    const BorderSide(color: Colors.white, width: 3),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.participantName.isNotEmpty
                        ? widget.participantName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.participantName.isNotEmpty
                    ? widget.participantName
                    : 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConnected
                    ? _getCallDuration()
                    : (widget.isOutgoing ? 'Calling...' : 'Connecting...'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCallDuration() {
    if (_callStartTime == null) {
      return '00:00';
    }
    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            onTap: _toggleMute,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
          border: Border.fromBorderSide(BorderSide(color: color, width: 2)),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
