import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import 'auth_provider.dart';
import '../../shared/widgets/auth_gate_bottom_sheet.dart';

class GuestHelper {
  // No static cache — AuthProvider is the single source of truth.
  // navigatorKey gives us access to it from anywhere without needing
  // a BuildContext passed in.

  static bool get isGuest {
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return false;
      return ctx.read<AuthProvider>().isGuest;
    } catch (_) {
      return false;
    }
  }

  static void guardAction(
      BuildContext context, {
        required VoidCallback action,
        String reason = 'do that',
      }) {
    if (isGuest) {
      AuthGateBottomSheet.show(context, reason: reason);
    } else {
      action();
    }
  }
}