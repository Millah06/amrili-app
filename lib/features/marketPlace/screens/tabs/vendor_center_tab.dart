import 'dart:io';

import 'package:everywhere/components/swicht.dart';
import 'package:everywhere/features/marketPlace/models/vendor_model.dart';
import 'package:everywhere/features/marketPlace/widgets/vendor_rejection_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../../../core/constant/api_constants.dart';
import '../../pages/edit_vendor_profile.dart';
import '../../providers/vendor_center_provider.dart';
import '../../widgets/navigation.dart';
import '../../widgets/qr_share_sheet.dart';
import '../../widgets/vendor_pending_view.dart';
import '../../widgets/vendor_pre_apply.dart';
import '../store_tabs/overview_tab.dart';
import '../store_tabs/product_tab.dart';
import '../store_tabs/store_order_tab.dart';

class VendorCenterTab extends StatelessWidget {
  const VendorCenterTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorCenterProvider>(
      builder: (context, p, _) {
        if (p.loading)  {

          return const Scaffold(
            backgroundColor: VendorTheme.background,
            body: Center(child: CircularProgressIndicator(color: VendorTheme.primary)),
          );
        }
        if (p.myVendor == null) return PreApplyView();
        if (p.isPending) return PendingView();
        if (p.isRejected) return RejectionView(rejectionMessage: p.rejectionMessage!, existingApplication: p.myVendor!,);
        return const _DashboardView();
      },
    );
  }
}


class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorCenterProvider>(
      builder: (context, p, _) {
        return Scaffold(
          backgroundColor: VendorTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, p),
                TabBar(
                  controller: _tabs,
                  indicatorColor: VendorTheme.primary,
                  labelColor: VendorTheme.primary,
                  unselectedLabelColor: VendorTheme.textMuted,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [Tab(text: 'Overview'), Tab(text: 'Orders'), Tab(text: 'Products')],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      OverviewTab(p: p),
                      StoreOrdersTab(vendorCenterProvider: p),
                      ProductTab(p: p),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, VendorCenterProvider vendorCenter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                // onTap: () => _pickLogo(context, vendorCenter),
                onTap: () {
                  vendorPush(context, EditVendorProfilePage());
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vendorCenter.myVendor!.logo.isNotEmpty
                          ? Image.network(vendorCenter.myVendor!.logo, width: 48, height: 48, fit: BoxFit.cover)
                          : _selectedImage != null ? SizedBox(
                        width: 48, height: 48,
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),

                      ) : Container(
                        width: 48, height: 48,
                        color: VendorTheme.surfaceVariant,
                        child: const Icon(Icons.storefront, color: VendorTheme.textMuted),
                      ),
                    ),
                    if (vendorCenter.myVendor!.logo.isEmpty)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: VendorTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendorCenter.myVendor!.name,
                        style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(vendorCenter.myVendor!.vendorType.label,
                        style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              // Share this store — opens the QR + link share sheet (Phase 2).
              IconButton(
                tooltip: 'Share store',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.ios_share_rounded,
                    color: VendorTheme.textPrimary, size: 20),
                onPressed: () => QRShareSheet.show(
                  context,
                  url: ApiConstants.storeUrl(vendorCenter.myVendor!.id),
                  entity: QREntity.store,
                  entityId: vendorCenter.myVendor!.id,
                  name: vendorCenter.myVendor!.name,
                  logoUrl: vendorCenter.myVendor!.logo,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => vendorCenter.toggleVisibility(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: vendorCenter.myVendor!.isVisible ? VendorTheme.accent.withOpacity(0.15) : VendorTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vendorCenter.myVendor!.isVisible ? VendorTheme.accent : VendorTheme.divider),
                  ),
                  child: Text(
                    vendorCenter.myVendor!.isVisible ? 'Online' : 'Offline',
                    style: TextStyle(
                        color: vendorCenter.myVendor!.isVisible ? VendorTheme.accent : VendorTheme.textMuted,
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20,),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VendorTheme.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Mode'),
                TinySwitch(value: vendorCenter.vendorIsVisible, onChanged: (value) async {
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
                  await vendorCenter.toggleVisibility();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                })
                 ]
            ),
          ),
        ],
      ),
    );
  }

  void _pickLogo(BuildContext context, VendorCenterProvider p) async {

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {

      return;
    };
    setState(() {
      _selectedImage = File(picked.path);
    });
    await p.uploadLogo(_selectedImage!, 'vendorLogo',);
  }
}


