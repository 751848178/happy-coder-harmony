part of '../session_detail.dart';

extension _SessionScreenMessageFileHandler on _SessionScreenState {
  void Function(String)? _createFilePathTapHandler() {
    final sessionId = widget.sessionId;
    if (sessionId.isEmpty) return null;
    // Reuse the cached handler when sessionId hasn't changed — avoids
    // creating a new closure on every _buildMessageBubble() call.
    if (_cachedFilePathTapHandlerSessionId == sessionId) {
      return _cachedFilePathTapHandler;
    }
    _cachedFilePathTapHandlerSessionId = sessionId;
    _cachedFilePathTapHandler = (String filePath) {
      final fileName = filePath.split('/').last;
      final uri = Uri.parse(
        AppRoutes.sessionFileDetail(sessionId) +
            '?path=${Uri.encodeComponent(filePath)}'
                '&name=${Uri.encodeComponent(fileName)}',
      );
      context.push(uri.toString());
    };
    return _cachedFilePathTapHandler;
  }
}
