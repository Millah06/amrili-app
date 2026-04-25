import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../providers/location_provider.dart';
import '../models/order_model.dart';
import '../providers/vendor_center_provider.dart';
import '../widgets/shared_widgets.dart';
// ─── Join with Branch ID ──────────────────────────────────────────────────────

class JoinWithIdForm extends StatefulWidget {
  const JoinWithIdForm({super.key});

  @override
  State<JoinWithIdForm> createState() => JoinWithIdFormState();
}

class JoinWithIdFormState extends State<JoinWithIdForm> {
  final _vendorIdCtrl = TextEditingController();

  String ? selectedState ;
  String ? selectedLga;

  final _area    = TextEditingController();
  final _street  = TextEditingController();
  int _deliveryTime = 30;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _foundVendor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pov = context.read<LocationProvider>();
      final states = pov.states;
      if (states.isEmpty) {
        pov.loadStates();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_vendorIdCtrl, _area, _street]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final location = context.watch<LocationProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        _infoBox(
          'A vendor owner can share their Vendor ID with you. '
              'Enter it below to add a new branch location under their account.',
        ),
        const SizedBox(height: 20),
        // Vendor ID input + lookup
        Row(
          children: [
            Expanded(
              child: VTextField(
                controller: _vendorIdCtrl,
                label: 'Vendor ID',
                hint: 'Paste vendor ID here',
              ),
            ),
            const SizedBox(width: 10),
            VSmallButton(
              label: 'Look up',
              color: VendorTheme.primary,
              textColor: Colors.white,
              onTap: _lookup,
            ),
          ],
        ),
        if (_foundVendor != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VendorTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VendorTheme.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: VendorTheme.accent, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_foundVendor!['name'],
                        style: const TextStyle(
                            color: VendorTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(_foundVendor!['vendorType'],
                        style: const TextStyle(
                            color: VendorTheme.textMuted, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.check_circle, color: VendorTheme.accent, size: 18),
              ],
            ),
          ),
        ],
        // Branch ID tip with copy
        const SizedBox(height: 20),
        if (_foundVendor != null) ...[
          const Divider(color: VendorTheme.divider),
          const SizedBox(height: 16),
          const Text('New Branch Location',
              style: TextStyle(
                  color: VendorTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          VDropdown<LocationState>(
            label: location.loadingLocation ? 'Loading states...' : 'State',
            value: location.selectedState,
            enabled: !location.loadingLocation && location.states.isNotEmpty,
            items: location.states
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (s) {
              if (s != null) location.pickState(s);
              setState(() {
                selectedState = s!.name;
              });
            },
          ),
          const SizedBox(height: 10),
          // Step 2 — LGA (shown once state is picked)
          if (location.selectedState != null) ...[
            const SizedBox(height: 12),
            VDropdown<LocationLga>(
              label: 'LGA',
              value: location.selectedLga,
              enabled: location.lgas.isNotEmpty,
              items: location.lgas
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                  .toList(),
              onChanged: (l) {
                if (l != null) location.pickLga(l);
                setState(() {
                  selectedLga = l!.name;
                });

              },
            ),
          ],

          const SizedBox(height: 10),
          VTextField(controller: _area, label: 'Area / Town'),
          const SizedBox(height: 10),
          VTextField(controller: _street, label: 'Street'),
          const SizedBox(height: 10),
          VDropdown<int>(
            label: 'Estimated Delivery Time',
            value: _deliveryTime,
            items: [15, 20, 30, 45, 60, 90]
                .map((t) => DropdownMenuItem(value: t, child: Text('$t minutes')))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => _deliveryTime = v); },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: VendorTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          VButton(label: 'Add Branch to Vendor', loading: _loading, onTap: _submit),
        ],
        // How to share vendor ID
        const SizedBox(height: 24),
        _shareIdTip(),
      ],
    );
  }

  void _lookup() async {
    final id = _vendorIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final p = context.read<VendorCenterProvider>();
      final data = await p.api.get('/vendor/$id');
      setState(() { _foundVendor = data; });
    } catch (e) {
      setState(() {
        _foundVendor = null;
        _error = 'Vendor not found. Check the ID and try again.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _submit() async {
    if (selectedState!.isEmpty || _area.text.isEmpty) {
      setState(() => _error = 'Please fill in all location fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final p = context.read<VendorCenterProvider>();
      await p.api.post('/branch/add', {
        'vendorId': _foundVendor!['id'],
        'state': selectedState,
        'lga': selectedLga,
        'area': _area.text.trim(),
        'street': _street.text.trim(),
        'estimatedDeliveryTime': _deliveryTime,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch added!'), backgroundColor: VendorTheme.accent),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _shareIdTip() {
    final p = context.read<VendorCenterProvider>();
    final vendorId = p.myVendor?.id;
    if (vendorId == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share your Vendor ID',
              style: TextStyle(
                  color: VendorTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Give this ID to someone managing a different location for your business:',
              style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: VendorTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(vendorId,
                      style: const TextStyle(
                          color: VendorTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace')),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: vendorId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vendor ID copied'),
                        backgroundColor: VendorTheme.accent),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VendorTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, color: VendorTheme.primary, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VendorTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_outlined, color: VendorTheme.warning, size: 18),
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