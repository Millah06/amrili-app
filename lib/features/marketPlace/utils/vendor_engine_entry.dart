// lib/features/marketPlace/utils/vendor_engine_entry.dart
//
// Now delegates its provider set to `VendorScope` so the exact same providers
// back both the marketplace shell AND deep-link landing pages. Behaviour is
// unchanged from before — this is a pure extract-and-reuse refactor.
//
import 'package:everywhere/features/marketPlace/utils/vendor_engine_shell.dart';
import 'package:flutter/material.dart';

import 'vendor_scope.dart';

class VendorEngineEntry extends StatelessWidget {
  final String? searchParam;
  const VendorEngineEntry({super.key, this.searchParam});

  @override
  Widget build(BuildContext context) {
    return VendorScope(
      child: VendorEngineShell(searchParam: searchParam),
    );
  }
}