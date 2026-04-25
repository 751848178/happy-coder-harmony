/// Public types for message action handling.
///
/// Extracted from session_screen's private namespace so that independent
/// message-bubble widgets can reference action callbacks without coupling
/// to the session screen mega-library.

/// Choices available when a user long-presses a message bubble.
enum SessionMessageActionChoice {
  forward,
  saveTemplate,
  insertIntoComposer,
}

/// Callback signature for message-action handlers.
typedef SessionMessageActionHandler = Future<void> Function(
  SessionMessageActionChoice choice,
);
