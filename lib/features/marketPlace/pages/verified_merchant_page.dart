import 'dart:io';

import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../widgets/shared_widgets.dart';

class VerifiedMerchantPage extends StatefulWidget {
  const VerifiedMerchantPage({super.key});

  @override
  State<VerifiedMerchantPage> createState() => _VerifiedMerchantPageState();
}

class _VerifiedMerchantPageState extends State<VerifiedMerchantPage> {
  bool _showForm = false;
  File? _selectedImage;
  String?    _cacName;
  bool _loading = false;
  String? _error;
  bool _submitted = false;

  static const _fee = 2500; // verification fee in NGN

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VendorCenterProvider>();
    final vendor = p.myVendor;

    if (vendor == null) {
      return const Scaffold(
        backgroundColor: VendorTheme.background,
        body: VEmptyState(icon: Icons.storefront_outlined, title: 'No vendor found'),
      );
    }

    if (vendor.verified || _submitted) {
      return _AlreadyVerifiedView(alreadyVerified: vendor.verified);
    }

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: VendorTheme.background,
            expandedHeight: 220,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Icon(Icons.verified, color: Colors.white, size: 56),
                      SizedBox(height: 12),
                      Text('Verified Merchant',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Build trust. Grow faster.',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _showForm
                  ? _ApplicationForm(
                cacImage: _selectedImage,
                cacName: _cacName,
                loading: _loading,
                error: _error,
                onPickCac: _pickCac,
                onSubmit: _submit,
              )
                  : _BenefitsView(
                fee: _fee,
                onApply: () => setState(() => _showForm = true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCac() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _cacName  = picked.name;
    });
  }

  void _submit() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Please upload your CAC certificate');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final p = context.read<VendorCenterProvider>();
      // Upload CAC document
      await p.api.upload(
        '/vendor/upload/cac',
        _selectedImage!,
        _cacName!,
      );
      // Submit verification request
      await p.api.post('/vendor/verify/request', {});
      setState(() { _submitted = true; });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Benefits View ────────────────────────────────────────────────────────────

class _BenefitsView extends StatelessWidget {
  final int fee;
  final VoidCallback onApply;

  const _BenefitsView({required this.fee, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (Icons.verified,
      'Verified Badge',
      'A blue checkmark on your vendor card that customers instantly trust', VendorTheme.primary),
      (Icons.trending_up, 'Higher Ranking', 'Verified merchants rank higher in search results and vendor lists', VendorTheme.accent),
      (Icons.support_agent, 'Priority Support', 'Your appeals and support requests are handled first', const Color(0xFFA855F7)),
      (Icons.campaign_outlined, 'Featured Placement', 'Get featured on the homepage and category banners', VendorTheme.warning),
      (Icons.shield_outlined, 'Dispute Protection', 'Enhanced protection in buyer-seller disputes', const Color(0xFFEC4899)),
      (Icons.bar_chart_outlined, 'Advanced Analytics', 'Access detailed order analytics and customer insights', VendorTheme.primary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What you get',
            style: TextStyle(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 16),
        ...benefits.map((b) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VendorTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VendorTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: b.$4.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(b.$1, color: b.$4, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.$2,
                        style: const TextStyle(
                            color: VendorTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(b.$3,
                        style: const TextStyle(
                            color: VendorTheme.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
        // Pricing
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text('One-time Verification Fee',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text('₦${kFormatter.format(fee)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
              const SizedBox(height: 4),
              const Text('Paid once · Verified forever',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        VButton(
          label: 'Apply for Verification',
          icon: Icons.verified,
          onTap: onApply,
        ),
        const SizedBox(height: 8),
        const Text(
          'Manual review takes 1–3 business days. You will be notified once approved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: VendorTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Application Form ─────────────────────────────────────────────────────────

class _ApplicationForm extends StatelessWidget {
  final File? cacImage;
  final String? cacName;
  final bool loading;
  final String? error;
  final VoidCallback onPickCac;
  final VoidCallback onSubmit;

  const _ApplicationForm({
    required this.cacImage,
    required this.cacName,
    required this.loading,
    required this.error,
    required this.onPickCac,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification Application',
            style: TextStyle(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 6),
        const Text(
          'Upload your CAC certificate. Our team will manually review and approve your application.',
          style: TextStyle(color: VendorTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        // CAC Upload
        const Text('CAC Certificate',
            style: TextStyle(
                color: VendorTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickCac,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cacImage != null
                    ? VendorTheme.accent
                    : VendorTheme.divider,
              ),
            ),
            child: cacImage != null
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description, color: VendorTheme.accent, size: 32),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Document uploaded',
                        style: TextStyle(
                            color: VendorTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(cacName ?? '',
                        style: const TextStyle(
                            color: VendorTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Tap to change',
                        style: TextStyle(
                            color: VendorTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file_outlined,
                    color: VendorTheme.textMuted, size: 36),
                SizedBox(height: 8),
                Text('Tap to upload CAC certificate',
                    style: TextStyle(
                        color: VendorTheme.textMuted, fontSize: 13)),
                SizedBox(height: 4),
                Text('JPG, PNG or PDF accepted',
                    style: TextStyle(
                        color: VendorTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Payment note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VendorTheme.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: VendorTheme.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: VendorTheme.warning, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'After submitting, our team will contact you via your registered email with payment instructions. Verification is activated after fee confirmation.',
                  style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style:
              const TextStyle(color: VendorTheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        VButton(
          label: 'Submit Application',
          loading: loading,
          onTap: onSubmit,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Already Verified ─────────────────────────────────────────────────────────

class _AlreadyVerifiedView extends StatelessWidget {
  final bool alreadyVerified;
  const _AlreadyVerifiedView({required this.alreadyVerified});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                alreadyVerified
                    ? 'You\'re already verified!'
                    : 'Application Submitted!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                alreadyVerified
                    ? 'Your vendor account is verified. The blue badge is shown on your vendor card.'
                    : 'Our team will review your CAC certificate and contact you with payment instructions within 1–3 business days.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: VendorTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              VButton(
                label: 'Go Back',
                onTap: () => Navigator.pop(context),
                width: 160,
              ),
            ],
          ),
        ),
      ),
    );
  }
}