import 'dart:async';
import 'dart:io';

import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../../../shared/widgets/cover_photo_picker.dart';
import '../../../shared/widgets/logo_picker.dart';
import '../../marketPlace/widgets/shared_widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditVendorProfilePageState();
}

class _EditVendorProfilePageState extends State<EditProfilePage> {
  final _bio  = TextEditingController();
  final _website = TextEditingController();
  final _userName = TextEditingController();
  final _buzEmail = TextEditingController();
  final _location = TextEditingController();

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
      final user = context.read<UserProvider>().user;
      if (user != null) {
        _bio.text  = user.userProfile.bio;
        _website.text = user.userProfile.website;
        _userName.text = user.userProfile.userName;
        _buzEmail.text = user.userProfile.buzEmail;
        _location.text = user.userProfile.location;
      }
    });
  }

  bool? isAvailable;
  String  message = '';
  bool isChecking = false;

  Timer? _debounce;

  @override
  void dispose() {
    _bio.dispose();
    _website.dispose();
    _location.dispose();
    _buzEmail.dispose();
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
      body: Consumer<UserProvider>(
        builder: (context, u, _) {
          final user = u.user;
          if (user == null) return const SizedBox.shrink();

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
                existingUrl: user.userProfile.coverPhotoUrl,
                pendingImage: _pendingCoverImage,
                onPick: (coverImage, name) => setState(() {
                  _pendingCoverImage = coverImage;
                  _pendingCoverName  = name;
                }),
              ),
              const SizedBox(height: 20),
              // Logo
              const Text('Profile Picture',
                  style: TextStyle(
                      color: VendorTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LogoPicker(
                logo: false,
                existingUrl: user.userProfile.avatarUrl,
                pendingImage: _pendingLogoImage,
                onPick: (bytes, name) => setState(() {
                  _pendingLogoImage = bytes;
                  _pendingLogoName  = name;
                }),
              ),
              const SizedBox(height: 24),
              // Text fields
              const Text('Personal Details',
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
                          const Text('Name', style: TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(user.name, style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline, color: VendorTheme.textMuted, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _userName,
                cursorColor: Colors.white,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  _debounce = Timer(const Duration(milliseconds: 400), () async {
                    final handle = value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');

                    if (handle.isEmpty || handle.length < 3) {
                      setState(() {
                        isAvailable = null;
                        message = '';
                      });
                      return;
                    }

                    setState(() {
                      isChecking = true;
                    });

                    try {
                      final api = ApiService();
                      final response = await api.get('/users/check-handle/$handle');

                      setState(() {
                        isAvailable = response['available'];
                        message = response['message'];
                        isChecking = false;
                      });
                    } catch (e) {
                      setState(() {
                        isAvailable = false;
                        message = 'Error checking handle';
                        isChecking = false;
                      });
                    }
                  });
                },
                style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'User Handle',

                  suffixIcon: isChecking
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: VendorTheme.circularProgressColor,),
                    ),
                  )
                      : isAvailable == null
                      ? null
                      : Icon(
                    isAvailable! ? Icons.check : Icons.close,
                    color: isAvailable! ? VendorTheme.primary : Colors.red,
                  ),

                  helperText: message.isEmpty ? null : message,
                  helperStyle: TextStyle(
                    color: isAvailable == null
                        ? Colors.grey
                        : isAvailable!
                        ? VendorTheme.primary
                        : Colors.red,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: VendorTheme.primary, width: 1.5),
                  ),
                  labelStyle: const TextStyle(color: VendorTheme.textMuted),
                  hintStyle: const TextStyle(color: VendorTheme.textMuted),
                ),
              ),
              const SizedBox(height: 15),
              VTextField(controller: _bio, label: 'Bio', maxLines: 3),
              const SizedBox(height: 15),
              VTextField(
                  controller: _website,
                  label: 'Website',
                  keyboardType: TextInputType.text),
              const SizedBox(height: 15),
              VTextField(
                  controller: _buzEmail,
                  label: 'Business Email',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              VTextField(
                  controller: _location,
                  label: 'Location - State',
                  keyboardType: TextInputType.text),
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
                onTap: isAvailable == true ? () => _save(u) : null,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _save(UserProvider u) async {

    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService();
      String? handle = _userName.text.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      // Update text fields
      await api.put('/users/me/profile', {
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
        'website': _website.text.trim(),
        'businessEmail': _buzEmail.text.trim(),
        'userName' : handle,
      });

      // Upload cover if changed
      if (_pendingCoverImage!= null) {
        await api.upload(
          'users/me/upload/cover-photo',
          _pendingCoverImage!,
          _pendingCoverName!,
        );
      }

      // Upload logo if changed
      if (_pendingLogoImage != null) {
        await api.upload(
            'users/me/upload/profile-picture',
            _pendingLogoImage!,
            _pendingLogoName!
        );
      }

      // await p.init();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: VendorTheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}


