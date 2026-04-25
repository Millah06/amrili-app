import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../../../shared/widgets/cover_photo_picker.dart';
import '../../../shared/widgets/logo_picker.dart';
import '../widgets/shared_widgets.dart';

class EditVendorProfilePage extends StatefulWidget {
  const EditVendorProfilePage({super.key});

  @override
  State<EditVendorProfilePage> createState() => _EditVendorProfilePageState();
}

class _EditVendorProfilePageState extends State<EditVendorProfilePage> {
  final _desc  = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  File? _pendingCoverImage;
  File? _pendingLogoImage;
  String?    _pendingCoverName;
  String?    _pendingLogoName;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendor = context.read<VendorCenterProvider>().myVendor;
      if (vendor != null) {
        _desc.text  = vendor.description;
        _phone.text = vendor.phone;
        _email.text = vendor.email;
      }
    });
  }

  @override
  void dispose() {
    _desc.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Consumer<VendorCenterProvider>(
        builder: (context, p, _) {
          final vendor = p.myVendor;
          if (vendor == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cover photo
              const Text('Cover Photo',
                  style: TextStyle(
                      color: VendorTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CoverPicker(
                existingUrl: vendor.coverPhoto,
                pendingImage: _pendingCoverImage,
                onPick: (coverImage, name) => setState(() {
                  _pendingCoverImage = coverImage;
                  _pendingCoverName  = name;
                }),
              ),
              const SizedBox(height: 20),
              // Logo
              const Text('Vendor Logo',
                  style: TextStyle(
                      color: VendorTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LogoPicker(
                existingUrl: vendor.logo,
                pendingImage: _pendingLogoImage,
                onPick: (bytes, name) => setState(() {
                  _pendingLogoImage = bytes;
                  _pendingLogoName  = name;
                }),
              ),
              const SizedBox(height: 24),
              // Text fields
              const Text('Business Details',
                  style: TextStyle(
                      color: VendorTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              // Replace VTextField for name with this read-only display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: VendorTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Business Name', style: TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(vendor.name, style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline, color: VendorTheme.textMuted, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VTextField(controller: _desc, label: 'Description', maxLines: 3),
              const SizedBox(height: 10),
              VTextField(
                  controller: _phone,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              VTextField(
                  controller: _email,
                  label: 'Business Email',
                  keyboardType: TextInputType.emailAddress),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: VendorTheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              VButton(
                label: 'Save Changes',
                loading: _loading,
                onTap: () => _save(p),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _save(VendorCenterProvider p) async {
    // if (_name.text.isEmpty) {
    //   setState(() => _error = 'Business name cannot be empty');
    //   return;
    // }
    setState(() { _loading = true; _error = null; });
    try {
      // Update text fields
      await p.api.put('/vendor/profile', {
        'description': _desc.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
      });

      // Upload cover if changed
      if (_pendingCoverImage!= null) {
        await p.api.upload(
          'vendor/upload/coverPhoto',
          _pendingCoverImage!,
          _pendingCoverName!,
        );
      }

      // Upload logo if changed
      if (_pendingLogoImage != null) {
        await p.uploadLogo(_pendingLogoImage!, _pendingLogoName!);
      }

      await p.init();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: VendorTheme.accent,
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
}

