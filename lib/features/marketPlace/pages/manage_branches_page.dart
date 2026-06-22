import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/pages/add_delivery_zone.dart';
import 'package:everywhere/services/brain.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';

import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../models/vendor_model.dart';
import '../widgets/navigation.dart';
import '../widgets/shared_widgets.dart';

class ManageBranchesPage extends StatelessWidget {
  const ManageBranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Manage Branches',
            style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Consumer<VendorCenterProvider>(
        builder: (context, p, _) {
          final branches = p.myVendor?.branches ?? [];
          if (branches.isEmpty) {
            return const VEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No branches yet',
              subtitle: 'Add your first branch location',
            );
          }
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            itemBuilder: (_, i) => _BranchCard(branch: branches[i], p: p),
          )));
        },
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VendorCenterProvider p;

  const _BranchCard({required this.branch, required this.p});

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VendorTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: VendorTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${branch.area}, ${branch.lga}',
                          style: const TextStyle(
                              color: VendorTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('${branch.state} · ~${branch.estimatedDeliveryTime} min',
                          style: const TextStyle(
                              color: VendorTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                // Delete branch
                if (branch.managerUid == pov.currentUser
                    || p.myVendor!.ownerFirebaseUid == pov.currentUser) ...[
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: const Icon(Icons.delete_outline, color: VendorTheme.error, size: 20),
                  ),
                  // Next to the delete icon
                  GestureDetector(
                    onTap: () => _showEditDialog(context),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.edit_outlined, color: VendorTheme.textMuted, size: 20),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const Divider(color: VendorTheme.divider, height: 1),
          // Delivery zones
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                const Text('Delivery Zones',
                    style: TextStyle(
                        color: VendorTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                if (branch.managerUid == pov.currentUser
                    || p.myVendor!.ownerFirebaseUid == pov.currentUser) ...[
                  GestureDetector(
                    onTap: () => vendorPush(context, NewDeliveryAddress(branch: branch)),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: VendorTheme.primary, size: 17),
                        const SizedBox(width: 3),
                        const Text('Add Zone',
                            style: TextStyle(
                                color: VendorTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          if (branch.deliveryZones.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text('No delivery zones set up yet',
                  style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
            )
          else
            ...branch.deliveryZones.map((zone) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: VendorTheme.accent, size: 7),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${zone.area}, ${zone.lga}',
                        style: const TextStyle(
                            color: VendorTheme.textPrimary, fontSize: 13)),
                  ),
                  Text('₦${kFormatter.format(zone.deliveryFee)}',
                      style: const TextStyle(
                          color: VendorTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  if (branch.managerUid == pov.currentUser) ...[

                    GestureDetector(
                      onTap: () => _deleteZone(context, zone.id),
                      child: const Icon(Icons.close,
                          color: VendorTheme.textMuted, size: 17),
                    ),

                  ]

                ],
              ),
            )),
          const SizedBox(height: 10),
          // Add below delivery zones section:
          if (branch.isMainBranch) // check against FirebaseAuth.instance.currentUser?.uid
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(children: [
                const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Main Branch',
                  style: const TextStyle(color: VendorTheme.gold, fontSize: 18),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Delete Branch?',
                  style: TextStyle(
                      color: VendorTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete this branch and all its delivery zones. This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VendorTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Cancel',
                      color: VendorTheme.surfaceVariant,
                      textColor: VendorTheme.textSecondary,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VButton(
                      label: 'Delete',
                      color: VendorTheme.error,
                      onTap: () async {
                        Navigator.pop(context);
                        try {
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
                                      Text("Deleting Branch..."),
                                    ],
                                  ),
                                ),
                              ));
                          await p.api.delete('/branch/${branch.id}/delete');
                          await p.init();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: VendorTheme.error),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final timeCtrl = TextEditingController(text: branch.estimatedDeliveryTime.toString());
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Branch',
                  style: TextStyle(color:
                  VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              VTextField(controller: timeCtrl, label: 'Estimated Delivery Time (minutes)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: VButton(label: 'Cancel', color: VendorTheme.surfaceVariant, textColor: VendorTheme.textSecondary, onTap: () => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(child: VButton(label: 'Save', onTap: () async {
                  Navigator.pop(context);

                  try {

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
                                Text("Updating branch..."),
                              ],
                            ),
                          ),
                        ));
                    await p.api.put('/branch/${branch.id}/update', {
                      'estimatedDeliveryTime': int.tryParse(timeCtrl.text.trim()) ?? 30,
                    });
                    await p.init();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }


                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: VendorTheme.error),
                      );
                    }
                  }


                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }



  void _deleteZone(BuildContext context, String zoneId) async {
    try {
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
                  Text("Deleting zone..."),
                ],
              ),
            ),
          ));
      await p.api.delete('/branch/zone/$zoneId/delete');
      await p.init();
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: VendorTheme.error),
        );
      }
    }
  }

  void _showAssignManagerDialog(BuildContext context) {
    final ctrl = TextEditingController(text: branch.managerUid ?? '');
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assign Branch Manager', style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Enter the Firebase UID of the person who will manage this branch. They can add menu items and update order statuses for this branch only.', style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 14),
              VTextField(controller: ctrl, label: 'Manager Firebase UID'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: VButton(label: 'Cancel', color: VendorTheme.surfaceVariant, textColor: VendorTheme.textSecondary, onTap: () => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(child: VButton(label: 'Assign', onTap: () async {
                  Navigator.pop(context);
                  await p.api.put('/branch/${branch.id}/assign-manager', { 'managerUid': ctrl.text.trim() });
                  await p.init();
                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}