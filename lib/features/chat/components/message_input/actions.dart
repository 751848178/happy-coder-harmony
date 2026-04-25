part of 'message_input.dart';

void _submitMessage(_MessageInputState state) {
  final message = state._controller.text.trim();
  if (message.isEmpty || !state.widget.enabled) {
    return;
  }
  state.widget.onSendMessage?.call(message);
  state._controller.clear();
  if (state._isExpanded) {
    state._updateView(() => state._isExpanded = false);
  }
  state._focusNode.requestFocus();
}

void _toggleMessageInputExpand(_MessageInputState state) {
  state._updateView(() => state._isExpanded = !state._isExpanded);
  if (state._isExpanded) {
    state._focusNode.requestFocus();
  }
}
