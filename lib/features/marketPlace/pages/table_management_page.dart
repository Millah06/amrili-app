// lib/features/marketPlace/pages/vendor_center/table_management_page.dart
//
// PHASE 7 — DINE-IN
//
// Merchant surface for managing dine-in tables. Reached from the Vendor Center.
// Each table has a QR code customers scan to order while seated. Tables can be
// downloaded as a print-ready PDF (86 × 82 mm sticker sheets, 2 × 3 per A4).
//
import 'dart:math' show min;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:everywhere/components/tiny_switch.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../constraints/vendor_theme.dart';
import '../../../../core/constant/api_constants.dart';
import '../models/restaurant_table_model.dart';
import '../services/table_api_services.dart';
import '../widgets/qr_share_sheet.dart';

/// Minimal branch descriptor the page needs.
class TableBranchOption {
  final String id;
  final String label;
  const TableBranchOption({required this.id, required this.label});
}

class TableManagementPage extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String? vendorLogo;
  final List<TableBranchOption> branches;

  const TableManagementPage({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.branches,
    this.vendorLogo,
  });

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage> {
  final _api = TablesApiService();

  late String _branchId;
  List<RestaurantTableModel> _tables = [];
  bool _loading = true;
  bool _generatingPdf = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _branchId = widget.branches.isNotEmpty ? widget.branches.first.id : '';
    _load();
  }

  Future<void> _load() async {
    if (_branchId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Add a branch first before creating tables.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tables = await _api.listTables(
        vendorId: widget.vendorId,
        branchId: _branchId,
      );
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Couldn\'t load tables. Pull to retry.';
      });
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VendorTheme.surface),
    );
  }

  // ── Create ───────────────────────────────────────────────────────────────
  Future<void> _addTable() async {
    final result = await showModalBottomSheet<_NewTableData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTableSheet(),
    );
    if (result == null) return;
    try {
      final table = await _api.createTable(
        branchId: _branchId,
        tableNumber: result.tableNumber,
        capacity: result.capacity,
      );
      if (!mounted) return;
      setState(() => _tables = [..._tables, table]
        ..sort((a, b) => _numCompare(a.tableNumber, b.tableNumber)));
      _toast('Table ${table.tableNumber} added');
    } catch (e) {
      _toast(_clean(e));
    }
  }

  // ── Toggle active ─────────────────────────────────────────────────────────
  Future<void> _toggleActive(RestaurantTableModel t, bool value) async {
    setState(() => _replace(t.id, _copyActive(t, value)));
    try {
      final updated = await _api.updateTable(tableId: t.id, isActive: value);
      if (!mounted) return;
      setState(() => _replace(t.id, updated));
    } catch (e) {
      if (!mounted) return;
      setState(() => _replace(t.id, t));
      _toast(_clean(e));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _deleteTable(RestaurantTableModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VendorTheme.surface,
        title: Text('Remove table ${t.tableNumber}?',
            style: const TextStyle(color: VendorTheme.textPrimary)),
        content: const Text(
          'Customers will no longer be able to scan into this table. '
          'Tables with active orders can\'t be removed.',
          style: TextStyle(color: VendorTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteTable(t.id);
      if (!mounted) return;
      setState(() => _tables = _tables.where((x) => x.id != t.id).toList());
      _toast('Table ${t.tableNumber} removed');
    } catch (e) {
      _toast(_clean(e));
    }
  }

  // ── Show QR ───────────────────────────────────────────────────────────────
  void _showQr(RestaurantTableModel t) {
    QRShareSheet.show(
      context,
      url: ApiConstants.tableUrl(widget.vendorId, t.id),
      entity: QREntity.table,
      entityId: t.id,
      name: '${widget.vendorName} · Table ${t.tableNumber}',
      logoUrl: widget.vendorLogo,
    );
  }

  // ── PDF download ──────────────────────────────────────────────────────────
  Future<Uint8List> _qrBytes(String url) async {
    const size = 300.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size, size),
      ui.Paint()..color = const Color(0xFFFFFFFF),
    );
    final painter = QrPainter(
      data: url,
      version: QrVersions.auto,
      gapless: true,
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0F172A),
      ),
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0F172A),
      ),
    );
    painter.paint(canvas, const Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _downloadTablesPdf() async {
    if (_tables.isEmpty || _generatingPdf) return;
    setState(() => _generatingPdf = true);

    try {
      final branchLabel = widget.branches
          .firstWhere((b) => b.id == _branchId,
              orElse: () => const TableBranchOption(id: '', label: 'Branch'))
          .label;

      // Load fonts (fall back to Helvetica if network unavailable)
      pw.Font boldFont, regularFont;
      try {
        boldFont = await PdfGoogleFonts.interBold();
        regularFont = await PdfGoogleFonts.interRegular();
      } catch (_) {
        boldFont = pw.Font.helveticaBold();
        regularFont = pw.Font.helvetica();
      }

      // Generate QR PNG bytes for every table
      final qrImages = <pw.MemoryImage>[];
      for (final t in _tables) {
        final bytes = await _qrBytes(ApiConstants.tableUrl(widget.vendorId, t.id));
        qrImages.add(pw.MemoryImage(bytes));
      }

      // Build PDF — 2 cols × 3 rows = 6 stickers per A4 page
      final doc = pw.Document();
      const cols = 2;
      const rows = 3;
      const perPage = cols * rows;
      const stickerW = 86.0 * PdfPageFormat.mm;
      const stickerH = 82.0 * PdfPageFormat.mm;
      const colGap = 14.0 * PdfPageFormat.mm;
      const rowGap = 13.0 * PdfPageFormat.mm;

      for (int start = 0; start < _tables.length; start += perPage) {
        final end = min(start + perPage, _tables.length);
        final pageTables = _tables.sublist(start, end);
        final pageImages = qrImages.sublist(start, end);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
            build: (_) {
              return pw.Column(
                children: [
                  for (int r = 0; r < rows; r++) ...[
                    if (r > 0) pw.SizedBox(height: rowGap),
                    pw.SizedBox(
                      height: stickerH,
                      child: pw.Row(
                        children: [
                          for (int c = 0; c < cols; c++) ...[
                            if (c > 0) pw.SizedBox(width: colGap),
                            pw.SizedBox(
                              width: stickerW,
                              height: stickerH,
                              child: () {
                                final idx = r * cols + c;
                                if (idx < pageTables.length) {
                                  return _buildPdfSticker(
                                    table: pageTables[idx],
                                    qrImage: pageImages[idx],
                                    vendorName: widget.vendorName,
                                    branchLabel: branchLabel,
                                    boldFont: boldFont,
                                    regularFont: regularFont,
                                  );
                                }
                                return pw.SizedBox();
                              }(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      }

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${widget.vendorName}_Tables_$branchLabel.pdf',
      );
    } catch (e) {
      _toast('Failed to generate PDF: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('Tables',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: _branchId.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: VendorTheme.primary,
              onPressed: _addTable,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add table',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            color: VendorTheme.primary,
            backgroundColor: VendorTheme.surface,
            onRefresh: _load,
            child: Column(
              children: [
                if (widget.branches.length > 1) _branchSelector(),
                if (!_loading && _error == null && _tables.isNotEmpty)
                  _statsHeader(),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Chip-style horizontal branch picker
  Widget _branchSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: widget.branches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final b = widget.branches[i];
          final selected = b.id == _branchId;
          return GestureDetector(
            onTap: () {
              if (selected) return;
              setState(() => _branchId = b.id);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? VendorTheme.primary : VendorTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? VendorTheme.primary : VendorTheme.divider),
              ),
              child: Text(
                b.label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : VendorTheme.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Stats row: table count + active count + Download PDF button
  Widget _statsHeader() {
    final active = _tables.where((t) => t.isActive).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.table_restaurant_outlined,
            label: '${_tables.length} tables',
            color: VendorTheme.textSecondary,
            bg: VendorTheme.surface,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.circle,
            iconSize: 8,
            label: '$active active',
            color: const Color(0xFF22C55E),
            bg: const Color(0xFF22C55E),
            bgOpacity: 0.12,
          ),
          const Spacer(),
          _generatingPdf
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VendorTheme.primary))
              : GestureDetector(
                  onTap: _downloadTablesPdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: VendorTheme.primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded,
                            size: 15, color: VendorTheme.primary),
                        const SizedBox(width: 5),
                        Text('Download PDF',
                            style: GoogleFonts.inter(
                                color: VendorTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const _TableListSkeleton();
    if (_error != null) {
      return _CenteredState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_tables.isEmpty) {
      return _CenteredState(
        icon: Icons.table_restaurant_outlined,
        title: 'No tables yet',
        subtitle:
            'Create a table, print its QR, and place it on the table. Diners scan to order.',
        actionLabel: 'Add your first table',
        onAction: _addTable,
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _tables.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = _tables[i];
        return _TableCard(
          table: t,
          qrUrl: ApiConstants.tableUrl(widget.vendorId, t.id),
          onShowQr: () => _showQr(t),
          onDelete: () => _deleteTable(t),
          onToggleActive: (v) => _toggleActive(t, v),
        );
      },
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────
  void _replace(String id, RestaurantTableModel updated) {
    final idx = _tables.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    final copy = [..._tables];
    copy[idx] = updated;
    _tables = copy;
  }

  RestaurantTableModel _copyActive(RestaurantTableModel t, bool active) =>
      RestaurantTableModel(
        id: t.id,
        vendorId: t.vendorId,
        branchId: t.branchId,
        tableNumber: t.tableNumber,
        capacity: t.capacity,
        isActive: active,
      );

  int _numCompare(String a, String b) {
    final na = int.tryParse(a), nb = int.tryParse(b);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.compareTo(b);
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PDF sticker builder (top-level, no widget state needed) ──────────────────
pw.Widget _buildPdfSticker({
  required RestaurantTableModel table,
  required pw.MemoryImage qrImage,
  required String vendorName,
  required String branchLabel,
  required pw.Font boldFont,
  required pw.Font regularFont,
}) {
  const darkBg = PdfColor(0.043, 0.067, 0.125);     // #0B1120
  const cyanAccent = PdfColor(0.129, 0.827, 0.929); // #21D3ED
  const mutedText = PdfColor(0.580, 0.639, 0.722);  // #94A3B8

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: PdfColors.blueGrey300,
        style: pw.BorderStyle.dashed,
        width: 0.5,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(color: darkBg),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                vendorName,
                style: pw.TextStyle(
                    font: boldFont, fontSize: 10, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                branchLabel,
                style: pw.TextStyle(
                    font: regularFont, fontSize: 7.5, color: mutedText),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        // QR code
        pw.Expanded(
          child: pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Image(qrImage, fit: pw.BoxFit.contain),
            ),
          ),
        ),
        // Footer
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(color: darkBg),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'TABLE ${table.tableNumber}  ·  ${table.capacity} SEATS',
                style: pw.TextStyle(
                    font: boldFont, fontSize: 8.5, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'SCAN TO ORDER',
                style: pw.TextStyle(
                    font: boldFont, fontSize: 7, color: cyanAccent),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Modern table card ─────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final RestaurantTableModel table;
  final String qrUrl;
  final VoidCallback onShowQr;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _TableCard({
    required this.table,
    required this.qrUrl,
    required this.onShowQr,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: table.isActive
              ? VendorTheme.primary.withValues(alpha: 0.35)
              : VendorTheme.divider,
        ),
      ),
      child: Row(
        children: [
          // Mini QR preview
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: QrImageView(
              data: qrUrl,
              version: QrVersions.auto,
              gapless: true,
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table ${table.tableNumber}',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _Chip(
                      label: '${table.capacity} seats',
                      color: VendorTheme.textSecondary,
                      bg: VendorTheme.background,
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      label: table.isActive ? 'Active' : 'Inactive',
                      color: table.isActive
                          ? const Color(0xFF22C55E)
                          : VendorTheme.textMuted,
                      bg: table.isActive
                          ? const Color(0xFF22C55E)
                          : VendorTheme.divider,
                      bgOpacity: 0.15,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Active toggle
          TinySwitch(value: table.isActive, onChanged: onToggleActive),
          const SizedBox(width: 2),
          // 3-dot menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: VendorTheme.textMuted, size: 20),
            color: VendorTheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'qr') onShowQr();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'qr',
                child: Row(children: [
                  const Icon(Icons.qr_code_2_rounded,
                      color: VendorTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  const Text('Show QR',
                      style: TextStyle(color: VendorTheme.textPrimary)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline,
                      color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 10),
                  const Text('Remove',
                      style: TextStyle(color: Color(0xFFEF4444))),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Small reusable pill chip used inside _TableCard and _statsHeader
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final double bgOpacity;

  const _Chip({
    required this.label,
    required this.color,
    required this.bg,
    this.bgOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11.5, fontWeight: FontWeight.w500)),
    );
  }
}

// Stat chip used in the stats header row
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final double bgOpacity;
  final double iconSize;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    this.bgOpacity = 1.0,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(8),
        border: bgOpacity == 1.0
            ? Border.all(color: VendorTheme.divider)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Add-table sheet ───────────────────────────────────────────────────────────
class _NewTableData {
  final String tableNumber;
  final int capacity;
  const _NewTableData(this.tableNumber, this.capacity);
}

class _AddTableSheet extends StatefulWidget {
  const _AddTableSheet();
  @override
  State<_AddTableSheet> createState() => _AddTableSheetState();
}

class _AddTableSheetState extends State<_AddTableSheet> {
  final _numberCtrl = TextEditingController();
  int _capacity = 4;

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: VendorTheme.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New table',
                style: GoogleFonts.poppins(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 17)),
            const SizedBox(height: 16),
            TextField(
              controller: _numberCtrl,
              style: const TextStyle(color: VendorTheme.textPrimary),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: _dec('Table number or label', 'e.g. 5 or Patio-2'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Seats',
                    style: TextStyle(color: VendorTheme.textSecondary)),
                const Spacer(),
                _stepBtn(Icons.remove,
                    () => setState(() => _capacity = (_capacity - 1).clamp(1, 50))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('$_capacity',
                      style: GoogleFonts.inter(
                          color: VendorTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                _stepBtn(Icons.add,
                    () => setState(() => _capacity = (_capacity + 1).clamp(1, 50))),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final n = _numberCtrl.text.trim();
                  if (n.isEmpty) return;
                  Navigator.pop(context, _NewTableData(n, _capacity));
                },
                child: Text('Create',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VendorTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: VendorTheme.divider),
          ),
          child: Icon(icon, color: VendorTheme.textPrimary, size: 18),
        ),
      );

  InputDecoration _dec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: VendorTheme.textSecondary),
        hintStyle: const TextStyle(color: VendorTheme.textMuted),
        filled: true,
        fillColor: VendorTheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendorTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendorTheme.primary),
        ),
      );
}

// ── Reusable states ───────────────────────────────────────────────────────────
class _CenteredState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _CenteredState({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(icon, size: 56, color: VendorTheme.textMuted),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: VendorTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: VendorTheme.textMuted, fontSize: 13.5)),
          ),
        ],
        const SizedBox(height: 22),
        Center(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: VendorTheme.primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: onAction,
            child: Text(actionLabel,
                style: const TextStyle(color: VendorTheme.primary)),
          ),
        ),
      ],
    );
  }
}

class _TableListSkeleton extends StatelessWidget {
  const _TableListSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 82,
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VendorTheme.divider),
        ),
      ),
    );
  }
}
