import 'package:everywhere/features/marketPlace/models/vendor_model.dart';
import 'package:everywhere/features/marketPlace/widgets/navigation.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:everywhere/features/marketPlace/widgets/vendor_apply.dart';
import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';

class RejectionView extends StatelessWidget {

  final VendorModel existingApplication;

  final String rejectionMessage;
  const RejectionView({super.key, required this.rejectionMessage, required this.existingApplication});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VEmptyState(
                icon: Icons.hourglass_top_rounded,
                title: 'Application Rejected',
                subtitle: rejectionMessage,
                iconColor: VendorTheme.error,
              ),
              const SizedBox(height: 40,),
              Row(
                spacing: 10,
                children: [
                  Expanded(child: VButton(label: 'Resubmit Application', onTap: () {
                    vendorPush(context, ApplyView(existingApplication: existingApplication,));
                  })),
                  Expanded(child: VButton(label: 'Delete Application', color: VendorTheme.background, textColor: Colors.white, onTap: () {}))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}