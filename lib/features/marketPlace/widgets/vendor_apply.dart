import 'package:everywhere/features/marketPlace/models/vendor_model.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:everywhere/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';

import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../models/order_model.dart';

class ApplyView extends StatefulWidget {

  final VendorModel ? existingApplication;

  const ApplyView({super.key, this.existingApplication});

  @override
  State<ApplyView> createState() => ApplyViewState();
}

class ApplyViewState extends State<ApplyView> {

  final _name        = TextEditingController();
  final _description = TextEditingController();
  final _phone       = TextEditingController();
  final _email       = TextEditingController();

  String ? selectedState ;
  String  ? selectedLga;

  final _area        = TextEditingController();
  final _street      = TextEditingController();
  String _vendorType = 'restaurant';
  int _deliveryTime  = 30;

  bool get _isEditing => widget.existingApplication != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pov = context.read<LocationProvider>();
      final states = pov.states;
      if (states.isEmpty) {
        pov.loadStates();
      }
      if (_isEditing) {
        final application = widget.existingApplication!;
        _name.text  = application.name;
        _description.text  = application.description;
        _phone.text = application.phone;
        _email.text = application.email;
        selectedState = application.branches.first.state;
        selectedLga = application.branches.first.lga;
        _area.text = application.branches.first.area;
        _street.text = application.branches.first.street;

        _vendorType = application.vendorType.name;
        _deliveryTime = application.branches.first.estimatedDeliveryTime;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _phone, _email, _area, _street]) c.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    final p = Provider.of<VendorCenterProvider>(context);

    final location = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Become a Vendor',
            style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Business Information',
              style: TextStyle(color: VendorTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          VTextField(controller: _name, label: 'Business Name'),
          const SizedBox(height: 10),
          VTextField(controller: _description, label: 'Description', maxLines: 2),
          const SizedBox(height: 10),
          VDropdown<String>(
            label: 'Vendor Type',
            value: _vendorType,
            items: ['restaurant', 'grocery', 'drinks', 'retail']
                .map((t) => DropdownMenuItem(
              value: t,
              child: Text(t[0].toUpperCase() + t.substring(1)),
            ))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => _vendorType = v); },
          ),
          const SizedBox(height: 10),
          VTextField(controller: _phone, label: 'Phone Number', keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          VTextField(controller: _email, label: 'Business Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          const Text('First Branch Location',
              style: TextStyle(color: VendorTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
          VTextField(controller: _area, label: 'Area'),
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
          if (p.error != null) ...[
            const SizedBox(height: 12),
            Text(p.error!, style: const TextStyle(color: VendorTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          VButton(
            label: 'Submit Application',
            loading: p.loading,
            onTap: () => _submit(p),
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    ),
    );
  }

  void _submit(VendorCenterProvider p) async {
    if (_name.text.isEmpty || _description.text.isEmpty) return;
    await p.applyAsVendor({
      'name': _name.text.trim(),
      'vendorType': _vendorType,
      'description': _description.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'branch': {
        'state': selectedState,
        'lga': selectedLga,
        'area': _area.text.trim(),
        'street': _street.text.trim(),
        'estimatedDeliveryTime': _deliveryTime,
      },
    });
  }
}