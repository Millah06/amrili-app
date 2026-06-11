// lib/features/marketPlace/pages/vendor_center/table_management_page.dart
//
// PHASE 7 — DINE-IN
//
// Merchant surface for managing dine-in tables. Reached from the Vendor Center.
// A restaurant owner/manager creates tables here; each table has a printable QR
// (reusing the Phase-2 AmrilQRCode via QRShareSheet) that a customer scans to
// open the store already "seated" at that table.
//
// Design intent (matches the dark VendorTheme used across the vendor center):
//   • Branch context up top (a vendor can run several branches; tables are
//     per-branch, so we make the active branch explicit and switchable).
//   • Each table is a calm card: number badge, capacity, active switch, and the
//     two primary actions a merchant actually wants — show/print the QR, and
//     remove. Destructive delete is guarded server-side (active orders block it)
//     and confirmed client-side.
//   • Full state coverage: skeleton while loading, friendly empty state with a
//     single clear CTA, inline error with retry. No dead ends.
//
import 'package:everywhere/components/swicht.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constraints/vendor_theme.dart';
import '../../../../core/constant/api_constants.dart';
import '../models/restaurant_table_model.dart';
import '../services/table_api_services.dart';
import '../widgets/qr_share_sheet.dart';

/// Minimal branch descriptor the page needs. The Vendor Center already has the
/// vendor's branches loaded, so it maps them into these (id + human label).
class TableBranchOption {
  final String id;
  final String label; // e.g. "Lekki Phase 1" / "Main branch"
  const TableBranchOption({required this.id, required this.label});
}

class TableManagementPage extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String? vendorLogo; // dropped into the QR centre for brand recognition
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
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to the first branch. (If a vendor somehow has no branch we show
    // the empty/error state rather than crashing.)
    _branchId =
    widget.branches.isNotEmpty ? widget.branches.first.id : '';
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
        _error = 'Couldn’t load tables. Pull to retry.';
      });
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VendorTheme.surface),
    );
  }

  // ── Create ──────────────────────────────────────────────────────────────
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

  // ── Active toggle ─────────────────────────────────────────────────────────
  Future<void> _toggleActive(RestaurantTableModel t, bool value) async {
    // Optimistic flip for snappiness; revert on failure.
    setState(() => _replace(t.id, t.isActive == value ? t : _copyActive(t, value)));
    try {
      final updated =
      await _api.updateTable(tableId: t.id, isActive: value);
      if (!mounted) return;
      setState(() => _replace(t.id, updated));
    } catch (e) {
      if (!mounted) return;
      setState(() => _replace(t.id, t)); // revert
      _toast(_clean(e));
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────
  Future<void> _deleteTable(RestaurantTableModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VendorTheme.surface,
        title: Text('Remove table ${t.tableNumber}?',
            style: const TextStyle(color: VendorTheme.textPrimary)),
        content: const Text(
          'Customers will no longer be able to scan into this table. '
              'Tables with active orders can’t be removed.',
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
      _toast(_clean(e)); // server returns the "active orders" reason here
    }
  }

  // ── QR ──────────────────────────────────────────────────────────────────
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
      // Single, obvious primary action.
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
      body: RefreshIndicator(
        color: VendorTheme.primary,
        backgroundColor: VendorTheme.surface,
        onRefresh: _load,
        child: Column(
          children: [
            if (widget.branches.length > 1) _branchSelector(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // Branch chooser — only shown when there's a real choice to make.
  Widget _branchSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _branchId,
            isExpanded: true,
            dropdownColor: VendorTheme.surface,
            iconEnabledColor: VendorTheme.textSecondary,
            style: const TextStyle(color: VendorTheme.textPrimary),
            items: widget.branches
                .map((b) => DropdownMenuItem(
              value: b.id,
              child: Text(b.label),
            ))
                .toList(),
            onChanged: (v) {
              if (v == null || v == _branchId) return;
              setState(() => _branchId = v);
              _load();
            },
          ),
        ),
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
      itemBuilder: (_, i) => _TableCard(
        table: _tables[i],
        onShowQr: () => _showQr(_tables[i]),
        onDelete: () => _deleteTable(_tables[i]),
        onToggleActive: (v) => _toggleActive(_tables[i], v),
      ),
    );
  }

  // ── small helpers ─────────────────────────────────────────────────────────
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

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}

// ─── Table card ────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final RestaurantTableModel table;
  final VoidCallback onShowQr;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _TableCard({
    required this.table,
    required this.onShowQr,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final dim = !table.isActive; // visually de-emphasise inactive tables
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dim ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: Row(
          children: [
            // Number badge — the at-a-glance identity of the card.
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VendorTheme.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                table.tableNumber,
                style: GoogleFonts.poppins(
                  color: VendorTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + capacity.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table ${table.tableNumber}',
                      style: GoogleFonts.inter(
                          color: VendorTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Seats ${table.capacity}',
                      style: const TextStyle(
                          color: VendorTheme.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
            // QR action.
            IconButton(
              tooltip: 'Show QR',
              onPressed: onShowQr,
              icon: const Icon(Icons.qr_code_2_rounded,
                  color: VendorTheme.primary),
            ),
            // Active toggle.
            TinySwitch(value: table.isActive, onChanged:  onToggleActive,),
            // Switch(
            //   value: table.isActive,
            //   activeColor: VendorTheme.primary,
            //   onChanged: onToggleActive,
            // ),
            // Delete.
            IconButton(
              tooltip: 'Remove',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add-table sheet ─────────────────────────────────────────────────────────
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
            // Table number / label.
            TextField(
              controller: _numberCtrl,
              style: const TextStyle(color: VendorTheme.textPrimary),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: _dec('Table number or label', 'e.g. 5 or Patio-2'),
            ),
            const SizedBox(height: 16),
            // Capacity stepper.
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

// ─── Reusable states ─────────────────────────────────────────────────────────
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
    // Scrollable so RefreshIndicator works even when "empty".
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

// Lightweight shimmer-free skeleton (3 placeholder rows).
class _TableListSkeleton extends StatelessWidget {
  const _TableListSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 74,
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VendorTheme.divider),
        ),
      ),
    );
  }
}