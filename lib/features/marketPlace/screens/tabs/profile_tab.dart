import 'package:everywhere/components/swicht.dart';
import 'package:everywhere/features/wallet/pages/withdraw_bank_screen.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/screens/pages/notification_screen.dart';
import 'package:everywhere/screens/privacy_policy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../../support/help_center.dart';
import '../../pages/add_branch_page.dart';
import '../../pages/edit_vendor_profile.dart';
import '../../pages/manage_branches_page.dart';
import '../../pages/merchant_balance_page.dart';
import '../../pages/merchant_trust_page.dart';
import '../../pages/verified_merchant_page.dart';
import '../../providers/vendor_center_provider.dart';
import '../../widgets/navigation.dart';
import '../../widgets/shared_widgets.dart';


class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {

    final user = context.watch<VendorCenterProvider>();

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text('Profile',
                style: TextStyle(color: VendorTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Avatar + name
            Center(
              child: Column(
                children: [
                  user.myVendor == null ? CircleAvatar(
              radius: 36,
                backgroundColor: VendorTheme.surfaceVariant,
                backgroundImage: null,
                child: const Icon(Icons.person, color: VendorTheme.textMuted, size: 50),) :
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: VendorTheme.surfaceVariant,
                    backgroundImage: user.myVendor?.logo != null &&  user.myVendor!.logo.isNotEmpty ?
                    NetworkImage(user.myVendor!.logo) : null,
                    child: user.myVendor!.logo.isEmpty
                        ? const Icon(Icons.person, color: VendorTheme.textMuted, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.myVendor?.name ?? user.myVendor?.email ?? 'User',
                    style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if ( user.myVendor?.email != null)
                    Text( user.myVendor!.email,
                        style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Vendor section
            Consumer<VendorCenterProvider>(
              builder: (context, p, _) {
                if (p.myVendor == null || p.myVendor!.status != 'approved') return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Vendor Account',
                        style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VendorTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VendorTheme.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined, color: VendorTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.myVendor!.name,
                                    style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.w600)),
                                Text(p.myVendor!.status,
                                    style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          VStatusBadge(
                            label: p.myVendor!.isVisible ? 'Online' : 'Offline',
                            color: p.myVendor!.isVisible ? VendorTheme.accent : VendorTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Merchant Tools',
                        style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (p.myVendor!.isOwner(context.read<UserProvider>().user!.userId))
                    _tile(Icons.edit,  'Edit Profile', () {
                      vendorPush(context, EditVendorProfilePage());
                    }),
                    _tile(Icons.location_on_outlined, 'Add Delivery Address', () {
                      vendorPush(context, ManageBranchesPage());
                    }),
                    _tile(Icons.manage_accounts, 'Manage Branches', ()
                    {vendorPush(context, ManageBranchesPage());}),
                    _tile(Icons.add_business_outlined, 'Add Branch', () {
                      vendorPush(context, AddBranchPage());
                    }),
                    if (!p.myVendor!.verified)
                    _tile(Icons.verified_outlined, 'Apply for Verified Merchant', () {
                      vendorPush(context, VerifiedMerchantPage());
                    }),
                    _tile(Icons.workspace_premium_outlined, 'Verification & Trust',
                            () {
                          vendorPush(context, const MerchantTrustPage());
                        }),
                    _tile(Icons.account_balance_wallet_outlined, 'Balance & Settlements',
                            () => vendorPush(context, const MerchantBalancePage())),
                    if (p.myVendor!.isOwner(context.read<UserProvider>().user!.userId))
                    _tile(Icons.wallet, 'Withdraw to a bank',
                            () => vendorPush(context, WithdrawBankScreen())),
                    const SizedBox(height: 10),
                    if (p.myVendor!.isOwner(context.read<UserProvider>().user!.userId))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: VendorTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VendorTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, color: VendorTheme.textPrimary, size: 20),
                          const SizedBox(width: 12),
                          Text('Pay on Delivery', style: TextStyle(color: VendorTheme.textPrimary, fontSize: 14)),
                          const Spacer(),
                          TinySwitch(value: p.myVendor!.vendorAllowsPod, onChanged: (_) async {

                            showDialog(context: context,
                                barrierDismissible: false, builder: (_) => const Dialog(
                                  backgroundColor: VendorTheme.background,
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                                        SizedBox(width: 16),
                                        Text("Updating status..."),
                                      ],
                                    ),
                                  ),
                                ));
                            await p.togglePod();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                          })
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
            // Settings section
            const Text('Settings',
                style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _tile(Icons.notifications_outlined, 'Notifications', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
            }),
            _tile(Icons.help_outline, 'Help & Support', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HelpCenter()));
            }),
            _tile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
            }),
            const SizedBox(height: 8),
            if (user.myVendor != null && user.myVendor!.isOwner(context.read<UserProvider>().user!.userId))
            _tile(
              Icons.logout,
              'Deleted Store',
                  () => _signOut(context),
              color: VendorTheme.error,),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label,
      VoidCallback onTap, {Color color = VendorTheme.textPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: VendorTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }



  void _signOut(BuildContext context) async {



  }
}