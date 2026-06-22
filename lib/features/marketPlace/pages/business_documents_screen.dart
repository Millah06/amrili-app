// lib/features/marketPlace/pages/business_documents_screen.dart
//
// Compliance-light document upload screen for Level 2 → 3 (Business) upgrade.
// Supports: CAC Certificate, Address Proof, Status Report, MERMAT.
// Each slot uploads independently to POST /vendor/upload/business-document.
// Returns true when the user taps "Submit for review" so merchant_trust_page
// can refresh the trust status.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../providers/vendor_center_provider.dart';
import '../widgets/shared_widgets.dart';

class BusinessDocumentsScreen extends StatefulWidget {
  final Map<String, String> existingDocs;

  const BusinessDocumentsScreen({super.key, required this.existingDocs});

  @override
  State<BusinessDocumentsScreen> createState() =>
      _BusinessDocumentsScreenState();
}

class _BusinessDocumentsScreenState extends State<BusinessDocumentsScreen> {
  late final Map<String, String> _uploaded;
  final Map<String, bool> _uploading = {};
  bool _submitting = false;
  String? _error;

  static const _docTypes = [
    _DocType(
      key: 'cacCertificate',
      label: 'CAC Certificate',
      subtitle: 'Certificate of Incorporation or Business Name Registration',
      icon: Icons.business_outlined,
      required: true,
    ),
    _DocType(
      key: 'addressProof',
      label: 'Proof of Address',
      subtitle: 'Utility bill or bank statement (not older than 3 months)',
      icon: Icons.location_on_outlined,
      required: false,
    ),
    _DocType(
      key: 'statusReport',
      label: 'Status Report',
      subtitle: 'Annual returns or status report from CAC',
      icon: Icons.description_outlined,
      required: false,
    ),
    _DocType(
      key: 'mermat',
      label: 'MEMART',
      subtitle: 'Memorandum & Articles of Association (companies only)',
      icon: Icons.article_outlined,
      required: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _uploaded = Map.from(widget.existingDocs);
    for (final d in _docTypes) {
      _uploading[d.key] = false;
    }
  }

  bool get _canSubmit => _uploaded.containsKey('cacCertificate');

  Future<void> _pickAndUpload(_DocType doc) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading[doc.key] = true);
    try {
      final api = context.read<VendorCenterProvider>().api;
      final result = await api.uploadWithType(
        '/vendor/upload/business-document',
        File(picked.path),
        picked.name,
        type: doc.key,
      );
      if (mounted) {
        setState(() => _uploaded[doc.key] = result['url'] ?? '');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploading[doc.key] = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<VendorCenterProvider>().api.post(
        '/vendor/trust/pay-fee',
        {},
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('Business Documents',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VendorTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: VendorTheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: VendorTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload your CAC Certificate to apply for Business verification. '
                        'The other documents are optional but help speed up review.',
                        style: GoogleFonts.inter(
                            color: VendorTheme.textSecondary,
                            fontSize: 12.5,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ..._docTypes.map((doc) => _DocSlot(
                    doc: doc,
                    uploadedUrl: _uploaded[doc.key],
                    uploading: _uploading[doc.key] ?? false,
                    onTap: () => _pickAndUpload(doc),
                  )),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VendorTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: VendorTheme.error.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.inter(
                          color: VendorTheme.error, fontSize: 12.5)),
                ),
              ],
              const SizedBox(height: 24),
              VButton(
                label: _submitting
                    ? 'Submitting…'
                    : 'Submit for review',
                loading: _submitting,
                onTap: (!_canSubmit || _submitting) ? null : _submit,
              ),
              if (!_canSubmit) ...[
                const SizedBox(height: 10),
                Text(
                  'Upload your CAC Certificate to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DocSlot extends StatelessWidget {
  final _DocType doc;
  final String? uploadedUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _DocSlot({
    required this.doc,
    required this.uploadedUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = uploadedUrl != null && uploadedUrl!.isNotEmpty;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? VendorTheme.accent.withOpacity(0.4)
                : VendorTheme.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: uploaded
                    ? VendorTheme.accent.withOpacity(0.12)
                    : VendorTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                uploaded ? Icons.check_circle_outline : doc.icon,
                color:
                    uploaded ? VendorTheme.accent : VendorTheme.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(doc.label,
                          style: GoogleFonts.inter(
                              color: VendorTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5)),
                      if (doc.required) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VendorTheme.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Required',
                              style: GoogleFonts.inter(
                                  color: VendorTheme.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    uploaded ? 'Uploaded ✓' : doc.subtitle,
                    style: GoogleFonts.inter(
                      color: uploaded
                          ? VendorTheme.accent
                          : VendorTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (uploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: VendorTheme.primary),
              )
            else
              Icon(
                uploaded ? Icons.refresh : Icons.upload_outlined,
                color: VendorTheme.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _DocType {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool required;

  const _DocType({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.required,
  });
}
