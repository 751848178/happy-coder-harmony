part of 'socket_repository.dart';

extension SocketRepositoryRpcCache on SocketRepository {
  void _subscribeToSocketSession(String sessionId) {
    Logger.info('Session subscription uses user-scoped socket: $sessionId');
  }

  void _unsubscribeFromSocketSession(String sessionId) {
    Logger.info('Session unsubscription uses user-scoped socket: $sessionId');
  }

  Future<void> _sendSocketHeartbeat() async {
    if (_socket == null || !_socket!.connected) {
      return;
    }
    _socket!.emit('ping', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _clearSocketLocalSessionCache(String sessionId) async {
    try {
      await SessionComposerQueueService.instance.clearSession(sessionId);
      await SessionPreferencesService.instance.clearSession(sessionId);
      await SessionUiStateService.instance.clearSession(sessionId);
      await StorageService.instance.deleteSession(sessionId);
    } catch (error) {
      Logger.warning('Failed to clear cached session $sessionId: $error');
    }
  }
}
