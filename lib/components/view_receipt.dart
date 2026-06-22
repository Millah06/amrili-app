import 'dart:io';
import 'dart:ui' as ui;

import 'package:everywhere/components/formatters.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/models/transaction_model.dart';
import 'package:everywhere/providers/transaction_provider.dart';
import 'package:everywhere/services/receipt_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ViewReceipt extends StatefulWidget {
  final String transactionId;
  const ViewReceipt({super.key, required this.transactionId});

  @override
  State<ViewReceipt> createState() => _ViewReceiptState();
}

class _ViewReceiptState extends State<ViewReceipt> {
  final _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadDetail(widget.transactionId);
    });
  }

  @override
  void dispose() {
    context.read<TransactionProvider>().clearDetail();
    super.dispose();
  }

  Future<void> _shareAsImage() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing image…'), backgroundColor: kCardColor),
      );
      final boundary = _previewKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nexpay_receipt.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        title: 'NexPay Transaction Receipt',
        text: 'Get yours → ${AppLinkHandler.appLink}',
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share image: $e'), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Future<void> _shareAsPdf(TransactionModel tx) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF…'), backgroundColor: kCardColor),
    );
    await ReceiptBuilder().exportToPdf(tx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          'Receipt',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Center(child:
    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640),
    child: Consumer<TransactionProvider>(
        builder: (_, prov, __) {
          if (prov.isLoadingDetail) return const _ReceiptSkeleton();

          if (prov.error != null && prov.selectedTransaction == null) {
            return _ErrorBody(
              message: prov.error!,
              onRetry: () => prov.loadDetail(widget.transactionId),
            );
          }

          final tx = prov.selectedTransaction;
          if (tx == null) return const _ReceiptSkeleton();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: _ReceiptCard(transaction: tx),
                  ),
                ),
              ),
              _ActionBar(
                transaction: tx,
                onSharePdf: () => _shareAsPdf(tx),
                onShareImage: _shareAsImage,
              ),
            ],
          );
        },
      ),
    ),
  ),
  );
}
}

// ─────────────────────────────────────────────────────────────────────────────
// Receipt card — the visual receipt that can also be captured as an image
// ─────────────────────────────────────────────────────────────────────────────
class _ReceiptCard extends StatelessWidget {
  final TransactionModel transaction;
  const _ReceiptCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF177E85).withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark grid
          _WatermarkGrid(),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReceiptHeader(transaction: tx),
                const SizedBox(height: 20),
                _AmountSection(transaction: tx),
                const SizedBox(height: 16),
                _Divider(),
                const SizedBox(height: 16),
                if (tx.meta != null) ...[
                  _MetaDataSection(transaction: tx),
                  const SizedBox(height: 8),
                  _SpecialSection(transaction: tx),
                ],
                const SizedBox(height: 20),
                _Divider(dashed: true),
                const SizedBox(height: 12),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
      );
  }
}

class _WatermarkGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Opacity(
      opacity: 0.04,
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
          ),
          itemCount: 30,
          itemBuilder: (_, __) => Center(
            child: Transform.rotate(
              angle: 0.5,
              child: const Icon(Icons.receipt, size: 40, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ReceiptHeader extends StatelessWidget {
  final TransactionModel transaction;
  const _ReceiptHeader({required this.transaction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF177E85).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_rounded, color: kIconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NexPay',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                'Transaction Receipt',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      _StatusBadge(status: transaction.status, color: transaction.statusColor),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          status.toUpperCase(),
          style: GoogleFonts.inter(
            color: color, fontWeight: FontWeight.w700,
            fontSize: 10, letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _AmountSection extends StatelessWidget {
  final TransactionModel transaction;
  const _AmountSection({required this.transaction});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              kNaira,
              style: GoogleFonts.inter(
                color: kButtonColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              kFormatter.format(transaction.amount),
              style: GoogleFonts.inter(
                color: kButtonColor,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMMM d, yyyy · hh:mm a').format(transaction.createdAt),
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
      ],
    ),
  );
}

class _MetaDataSection extends StatelessWidget {
  final TransactionModel transaction;
  const _MetaDataSection({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fields = transaction.meta?.displayFields ?? {};
    final ref = transaction.displayRef;

    return Column(
      children: [
        // Always show reference
        _KvRow(
          label: 'Reference',
          value: ref,
          copyable: true,
        ),
        // Show type nicely
        _KvRow(label: 'Category', value: transaction.displayLabel),
        // Dynamic metaData fields
        ...fields.entries.map((e) {
          final isCopyable = e.key.toLowerCase().contains('token') ||
              e.key.toLowerCase().contains('id');
          final isHighlight = e.key == 'Bonus Earned' || e.key == 'bonusEarned';
          return _KvRow(
            label: _prettyKey(e.key),
            value: e.value,
            copyable: isCopyable,
            highlight: isHighlight,
          );
        }),
        if (transaction.message != null && transaction.message!.isNotEmpty)
          _KvRow(label: 'Note', value: transaction.message!),
      ],
    );
  }

  String _prettyKey(String k) {
    // 'productName' → 'Product Name', 'Business Name' → 'Business Name'
    return k
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final bool highlight;
  const _KvRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w400),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: highlight ? kIconColor : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: kCardColor,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 13, color: kIconColor),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Special sections — rendered below generic KV rows for bulk-data types
// ─────────────────────────────────────────────────────────────────────────────
class _SpecialSection extends StatelessWidget {
  final TransactionModel transaction;
  const _SpecialSection({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final meta = transaction.meta;
    if (meta == null) return const SizedBox.shrink();

    final pins = meta.pins;
    final serials = meta.serial;
    final waecTokens = meta.waecRegistrationTokens;
    final waecCards = meta.waecResultCards;

    if (pins != null && pins.isNotEmpty) {
      return _PinsSection(pins: pins, serials: serials ?? []);
    }
    if (waecTokens != null && waecTokens.isNotEmpty) {
      return _WaecTokenSection(tokens: waecTokens);
    }
    if (waecCards != null && waecCards.isNotEmpty) {
      return _WaecResultSection(cards: waecCards);
    }
    return const SizedBox.shrink();
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: GoogleFonts.inter(
        color: kIconColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _PinsSection extends StatelessWidget {
  final List<String> pins;
  final List<String> serials;
  const _PinsSection({required this.pins, required this.serials});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      const _SectionLabel('RECHARGE PINS'),
      ...List.generate(pins.length, (i) {
        final pin = pins[i];
        final serial = i < serials.length ? serials[i] : null;
        return _PinCard(index: i + 1, pin: pin, serial: serial);
      }),
    ],
  );
}

class _PinCard extends StatelessWidget {
  final int index;
  final String pin;
  final String? serial;
  const _PinCard({required this.index, required this.pin, this.serial});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PIN $index',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 3),
            Text(
              pin.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            if (serial != null)
              Text(
                'S/N: $serial',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
              ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: pin));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN copied'),
                duration: Duration(seconds: 1),
                backgroundColor: kCardColor,
              ),
            );
          },
          child: const Icon(Icons.copy_rounded, size: 16, color: kIconColor),
        ),
      ],
    ),
  );
}

class _WaecTokenSection extends StatelessWidget {
  final List<String> tokens;
  const _WaecTokenSection({required this.tokens});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      const _SectionLabel('REGISTRATION TOKENS'),
      ...List.generate(tokens.length, (i) => _TokenCard(
        label: 'Token ${i + 1}',
        value: tokens[i],
      )),
    ],
  );
}

class _WaecResultSection extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  const _WaecResultSection({required this.cards});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      const _SectionLabel('RESULT CHECKER CARDS'),
      ...List.generate(cards.length, (i) {
        final card = cards[i];
        return _ResultCard(
          index: i + 1,
          pin: card['Pin']?.toString() ?? '',
          serial: card['Serial']?.toString() ?? '',
        );
      }),
    ],
  );
}

class _TokenCard extends StatelessWidget {
  final String label;
  final String value;
  const _TokenCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 3),
            Text(
              value.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
              style: GoogleFonts.robotoMono(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Token copied'), duration: Duration(seconds: 1), backgroundColor: kCardColor),
            );
          },
          child: const Icon(Icons.copy_rounded, size: 16, color: kIconColor),
        ),
      ],
    ),
  );
}

class _ResultCard extends StatelessWidget {
  final int index;
  final String pin;
  final String serial;
  const _ResultCard({required this.index, required this.pin, required this.serial});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(
      children: [
        _TokenCard(label: 'PIN $index', value: pin),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Serial $index', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            Text(serial, style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    'Enjoy a better life with NexPay. Book flights, hotels, spend in foreign currencies, get virtual cards, pay all your bills.',
    style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
    textAlign: TextAlign.center,
  );
}

class _Divider extends StatelessWidget {
  final bool dashed;
  const _Divider({this.dashed = false});

  @override
  Widget build(BuildContext context) {
    if (!dashed) {
      return Divider(color: Colors.white.withOpacity(0.07), height: 1);
    }
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        const dashW = 6.0;
        const gap = 4.0;
        final count = (w / (dashW + gap)).floor();
        return Row(
          children: List.generate(count, (_) => Container(
            width: dashW,
            height: 1,
            margin: const EdgeInsets.only(right: gap),
            color: Colors.white.withOpacity(0.1),
          )),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action bar at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onSharePdf;
  final VoidCallback onShareImage;
  const _ActionBar({
    required this.transaction,
    required this.onSharePdf,
    required this.onShareImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasPins = (transaction.meta?.pins?.isNotEmpty ?? false) ||
        (transaction.meta?.waecRegistrationTokens?.isNotEmpty ?? false) ||
        (transaction.meta?.waecResultCards?.isNotEmpty ?? false);

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _Btn(
              label: hasPins ? 'Download & Share' : 'Share as PDF',
              icon: Icons.picture_as_pdf_rounded,
              onTap: onSharePdf,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Btn(
              label: 'Share as Image',
              icon: Icons.image_rounded,
              onTap: onShareImage,
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: kButtonColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading & error states
// ─────────────────────────────────────────────────────────────────────────────
class _ReceiptSkeleton extends StatelessWidget {
  const _ReceiptSkeleton();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkBox(w: 120, h: 20),
              _SkBox(w: 70, h: 24, r: 20),
            ],
          ),
          const SizedBox(height: 28),
          Center(child: _SkBox(w: 180, h: 42)),
          const SizedBox(height: 10),
          Center(child: _SkBox(w: 140, h: 14)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          ...List.generate(5, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkBox(w: 90, h: 12),
                _SkBox(w: 120, h: 12),
              ],
            ),
          )),
        ],
      ),
    ),
  );
}

class _SkBox extends StatefulWidget {
  final double w, h, r;
  const _SkBox({required this.w, required this.h, this.r = 6});

  @override
  State<_SkBox> createState() => _SkBoxState();
}

class _SkBoxState extends State<_SkBox> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  late final _anim = Tween(begin: 0.04, end: 0.10).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.w, height: widget.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_anim.value),
        borderRadius: BorderRadius.circular(widget.r),
      ),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white12),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: Colors.white38, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(color: const Color(0xFF177E85), borderRadius: BorderRadius.circular(12)),
              child: Text('Retry', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    ),
  );
}