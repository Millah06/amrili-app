import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';


import '../../../features/marketPlace/providers/vendor_center_provider.dart';

import '../../../providers/location_provider.dart';
import '../models/order_model.dart';
import '../widgets/shared_widgets.dart';
import 'join_with_id.dart';

class AddBranchPage extends StatefulWidget {
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Add Branch',
            style: TextStyle(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: VendorTheme.primary,
          labelColor: VendorTheme.primary,
          unselectedLabelColor: VendorTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'New Branch'),
            Tab(text: 'Join with Branch ID'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewBranchForm(),
          JoinWithIdForm(),
        ],
      ),
    );
  }
}

// ─── New Branch Form ──────────────────────────────────────────────────────────

class _NewBranchForm extends StatefulWidget {
  const _NewBranchForm();

  @override
  State<_NewBranchForm> createState() => _NewBranchFormState();
}

class _NewBranchFormState extends State<_NewBranchForm> {
  String ? selectedState ;
  String selectedLga     = '';
  final _area    = TextEditingController();
  final _street  = TextEditingController();
  int _deliveryTime = 30;
  bool _loading = false;
  String? _error;



  @override
  void dispose() {
    for (final c in [ _area, _street]) c.dispose();
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
          'This adds a new physical location to your vendor account. '
              'Each branch has its own menu, delivery zones and estimated delivery time.',
        ),
        const SizedBox(height: 20),
        // Step 1 — State
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
        VButton(
          label: 'Add Branch',
          loading: _loading,
          onTap: _submit,
        ),
      ],
    );
  }

  void _submit() async {
    if (selectedState!.isEmpty || selectedLga.isEmpty || _area.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final p = context.read<VendorCenterProvider>();
      final vendor = p.myVendor!;
      await p.api.post('/branch/add', {
        'vendorId': vendor.id,
        'state': selectedState,
        'lga': selectedLga,
        'area': _area.text.trim(),
        'street': _street.text.trim(),
        'estimatedDeliveryTime': _deliveryTime,
      });
      await p.init();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch added successfully'),
            backgroundColor: VendorTheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VendorTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: VendorTheme.primary, size: 18),
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

