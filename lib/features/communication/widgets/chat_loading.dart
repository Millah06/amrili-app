import 'package:flutter/material.dart';

import '../theme/chat_theme.dart';

/// Runs [task] while showing a non-dismissible loading overlay, then returns
/// the task's result. Use for chat network actions (room creation, group
/// add/remove/leave) that previously ran with no feedback.
Future<T> runWithChatLoader<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const Center(
      child: SizedBox(
        width: 46,
        height: 46,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(ChatTheme.brandBright),
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    // Close the loader if it's still up.
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
