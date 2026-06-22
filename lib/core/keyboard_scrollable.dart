// lib/core/keyboard_scrollable.dart
//
// Wraps any scroll view so that keyboard arrow / Page Up/Down / Home / End
// keys scroll it without the user having to click first.
//
// Usage:
//   KeyboardScrollable(
//     controller: _myScrollController,
//     child: ListView(..., controller: _myScrollController),
//   )
//
// On mobile this is a no-op (touch events drive scrolling; no hardware
// keyboard is assumed). On web / desktop, hovering over the widget
// requests focus so arrow keys take immediate effect.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardScrollable extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const KeyboardScrollable({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<KeyboardScrollable> createState() => _KeyboardScrollableState();
}

class _KeyboardScrollableState extends State<KeyboardScrollable> {
  final FocusNode _node = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (!kIsWeb) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!widget.controller.hasClients) return KeyEventResult.ignored;

    final pos = widget.controller.position;
    double? target;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      target = (pos.pixels + 80).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      target = (pos.pixels - 80).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      target = (pos.pixels + pos.viewportDimension * 0.85)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      target = (pos.pixels - pos.viewportDimension * 0.85)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      target = pos.minScrollExtent;
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      target = pos.maxScrollExtent;
    }

    if (target == null) return KeyEventResult.ignored;

    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    return MouseRegion(
      onEnter: (_) {
        if (!_node.hasFocus) _node.requestFocus();
      },
      onExit: (_) {
        if (_node.hasFocus) _node.unfocus();
      },
      child: Focus(
        focusNode: _node,
        onKeyEvent: _handleKey,
        child: widget.child,
      ),
    );
  }
}
