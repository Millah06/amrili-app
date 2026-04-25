import 'package:everywhere/features/marketPlace/providers/vendor_center_provider.dart';
import 'package:everywhere/features/marketPlace/widgets/vendor_apply.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../pages/add_branch_page.dart';
import '../pages/join_with_id.dart';
import 'navigation.dart';

class PreApplyView extends StatelessWidget {
  const PreApplyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Become a Vendor',
                  style: TextStyle(
                      color: VendorTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
              SizedBox(height: 8),
              Text(
                'Start selling your products to thousands of customers in your area.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VendorTheme.textSecondary),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendorTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {


                    vendorPush(context, ApplyView());

                    },
                  child: const Text('Apply to Become Vendor',
                      style: TextStyle(
                          color: VendorTheme.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
              SizedBox(height: 42),
              Text(
                'Or',
                textAlign: TextAlign.center,
                style: TextStyle(color: VendorTheme.textSecondary),
              ),
              Text(
                'Join the existing store owners with their id and become one of their branches',
                textAlign: TextAlign.center,
                style: TextStyle(color: VendorTheme.textSecondary),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendorTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    vendorPush(context, JoinWithId());},
                  child: const Text('Join as a branch',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),

            ],),
        ),
      ),
    );
  }
}

class JoinWithId extends StatelessWidget {
  const JoinWithId({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Join Branch',
            style: TextStyle(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 0),
        child: JoinWithIdForm(),
      ),
    );
  }
}
