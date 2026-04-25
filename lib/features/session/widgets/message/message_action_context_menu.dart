import 'dart:async';

import 'package:flutter/material.dart';

import '../../presentation/session_message_actions.dart';
import 'session_message_action_types.dart';

/// Builds an [EditableTextContextMenuBuilder] that appends message-action
/// shortcuts (forward, save template, insert into composer) to the default
/// context menu.
EditableTextContextMenuBuilder buildMessageActionContextMenu(
  SessionMessageActionHandler? onMessageAction,
) {
  return (context, editableTextState) {
    final buttonItems = onMessageAction == null
        ? editableTextState.contextMenuButtonItems
        : buildSessionMessageContextMenuButtonItems(
            baseItems: editableTextState.contextMenuButtonItems,
            onForward: () => triggerMessageSelectionAction(
              editableTextState: editableTextState,
              onMessageAction: onMessageAction,
              choice: SessionMessageActionChoice.forward,
            ),
            onSaveTemplate: () => triggerMessageSelectionAction(
              editableTextState: editableTextState,
              onMessageAction: onMessageAction,
              choice: SessionMessageActionChoice.saveTemplate,
            ),
            onInsertIntoComposer: () => triggerMessageSelectionAction(
              editableTextState: editableTextState,
              onMessageAction: onMessageAction,
              choice: SessionMessageActionChoice.insertIntoComposer,
            ),
          );
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  };
}

/// Hides the toolbar and fires the given [choice] via [onMessageAction].
void triggerMessageSelectionAction({
  required EditableTextState editableTextState,
  required SessionMessageActionHandler onMessageAction,
  required SessionMessageActionChoice choice,
}) {
  editableTextState.hideToolbar();
  ContextMenuController.removeAny();
  unawaited(onMessageAction(choice));
}
