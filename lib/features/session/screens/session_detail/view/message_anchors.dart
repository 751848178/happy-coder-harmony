part of '../session_detail.dart';

class _BuildContextAnchor extends StatelessWidget {
  const _BuildContextAnchor({
    required this.anchorId,
    required this.onAttach,
    required this.onDetach,
    required this.child,
  });

  final String anchorId;
  final void Function(String anchorId, BuildContext context) onAttach;
  final void Function(String anchorId, BuildContext context) onDetach;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RenderObjectAnchor(
      anchorId: anchorId,
      onAttach: onAttach,
      onDetach: onDetach,
      child: child,
    );
  }
}

class _RenderObjectAnchor extends SingleChildRenderObjectWidget {
  const _RenderObjectAnchor({
    required this.anchorId,
    required this.onAttach,
    required this.onDetach,
    required super.child,
  });

  final String anchorId;
  final void Function(String anchorId, BuildContext context) onAttach;
  final void Function(String anchorId, BuildContext context) onDetach;

  @override
  SingleChildRenderObjectElement createElement() =>
      _RenderObjectAnchorElement(this);

  @override
  RenderProxyBox createRenderObject(BuildContext context) => RenderProxyBox();
}

class _RenderObjectAnchorElement extends SingleChildRenderObjectElement {
  _RenderObjectAnchorElement(_RenderObjectAnchor super.widget);

  _RenderObjectAnchor get _anchorWidget => widget as _RenderObjectAnchor;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    // Register synchronously so the anchor context is available immediately
    // for _captureMessageViewportAnchor in the same frame.  The previous
    // postFrameCallback caused a one-frame delay that made anchor restoration
    // fall through to coarse estimation or fail entirely.
    _anchorWidget.onAttach(_anchorWidget.anchorId, this);
  }

  @override
  void activate() {
    super.activate();
    _anchorWidget.onAttach(_anchorWidget.anchorId, this);
  }

  @override
  void update(covariant _RenderObjectAnchor newWidget) {
    final previousWidget = _anchorWidget;
    super.update(newWidget);
    if (previousWidget.anchorId != newWidget.anchorId) {
      previousWidget.onDetach(previousWidget.anchorId, this);
    }
    _anchorWidget.onAttach(_anchorWidget.anchorId, this);
  }

  @override
  void deactivate() {
    _anchorWidget.onDetach(_anchorWidget.anchorId, this);
    super.deactivate();
  }
}
