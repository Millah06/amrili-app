import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';

class PendingView extends StatelessWidget {
  const PendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: VendorTheme.background,
      body: VEmptyState(
        icon: Icons.hourglass_top_rounded,
        title: 'Application Under Review',
        subtitle: 'Your store application is being reviewed. We will notify you once approved.',
      ),
    );
  }
}