// lib/features/legal/legal_hub_screen.dart
//
// "Legal & Policies" hub. One screen that lists every Amril legal document and
// opens it in the generic LegalDocumentPage. Reached from Settings → About →
// "Legal & Policies". Styled to match the dark settings area.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'legal_docs.dart';
import 'legal_document_page.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Legal & Policies',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final doc in kLegalDocs) _LegalTile(doc: doc),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Amrili Digital Services Limited',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final LegalDoc doc;
  const _LegalTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LegalDocumentPage(doc: doc)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13203A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(doc.icon, color: const Color(0xFF21D3ED), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doc.subtitle,
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF475569), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}