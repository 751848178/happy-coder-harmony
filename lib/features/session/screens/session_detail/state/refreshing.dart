part of '../session_detail.dart';

extension _SessionScreenRefreshing on _SessionScreenState {
  void _setSessionRefreshing(bool value) {
    if (_isRefreshingSessionState == value) {
      return;
    }

    if (value) {
      _refreshIconController.repeat();
    } else {
      _refreshIconController
        ..stop()
        ..reset();
    }

    _isRefreshingSessionStateN.value = value;
  }
}
