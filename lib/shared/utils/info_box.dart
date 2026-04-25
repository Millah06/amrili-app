import 'package:flutter/material.dart';

import '../../constraints/vendor_theme.dart';

class InfoBox extends StatelessWidget {

  final String text;
  final Icon? icon;
  final Color? color;
  const InfoBox({super.key, required this.text, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? VendorTheme.primary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (color ?? VendorTheme.primary).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          icon ?? const Icon(Icons.info_outline, color: VendorTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: VendorTheme.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
