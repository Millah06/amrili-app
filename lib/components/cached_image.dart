import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';

// Legacy helper retained for call sites that import it.
// Delegates to NetImage which handles web CORS / http→https upgrade.
Widget networkTemplate(String url) {
  return NetImage(
    url: url,
    borderRadius: BorderRadius.circular(12),
  );
}
