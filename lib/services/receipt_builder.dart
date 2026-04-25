import 'dart:io';

import 'package:everywhere/components/formatters.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/models/transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Generates and shares a PDF receipt for any transaction type.
/// Type detection is via [TransactionModel.type] — no more key sniffing.
class ReceiptBuilder {

  Future<void> exportToPdf(TransactionModel transaction) async {
    final meta = transaction.meta;
    final type = transaction.type;

    // ── Load assets ──────────────────────────────────────────────────────────
    final logoBytes  = await rootBundle.load('images/receipt.png');
    final smallBytes = await rootBundle.load('images/gift.png');
    final fontBytes  = await rootBundle.load('assets/fonts/DejaVuSans.ttf');

    final logoWm   = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final smallLogo = pw.MemoryImage(smallBytes.buffer.asUint8List());
    final ttf      = pw.Font.ttf(fontBytes.buffer.asByteData());

    // ── Category detection ───────────────────────────────────────────────────
    final isAirtime   = (type == 'airtime' || type == 'data') &&
        (meta?.pins?.isNotEmpty ?? false);
    final isWaecReg   = type == 'waec_reg' &&
        (meta?.waecRegistrationTokens?.isNotEmpty ?? false);
    final isWaecResult= type == 'waec_result' &&
        (meta?.waecResultCards?.isNotEmpty ?? false);

    // ── Shared calculations ──────────────────────────────────────────────────
    int? numberOfCards;
    double? pricePerCard;

    if (isAirtime) {
      numberOfCards = meta!.pins!.length;
      final totalStr = meta.actualAmount ?? transaction.amount.toString();
      final total = double.tryParse(totalStr.split(' ').first) ?? transaction.amount;
      pricePerCard = total / numberOfCards;
    }
    if (isWaecReg) {
      numberOfCards = meta!.waecRegistrationTokens!.length;
      pricePerCard = transaction.amount / numberOfCards;
    }
    if (isWaecResult) {
      numberOfCards = meta!.waecResultCards!.length;
      pricePerCard = transaction.amount / numberOfCards;
    }

    // ── Build PDF ────────────────────────────────────────────────────────────
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          buildBackground: (_) => pw.Center(
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 1,
                children: List.generate(21, (_) => pw.Center(
                  child: pw.Transform.rotate(
                    angle: 0.6,
                    child: pw.Container(
                      width: 80, height: 80,
                      child: pw.Image(logoWm),
                    ),
                  ),
                )),
              ),
            ),
          ),
        ),
        header: (ctx) {
          if (ctx.pageNumber != 1) return pw.SizedBox();
          return _buildHeader(
            ttf: ttf,
            smallLogo: smallLogo,
            transaction: transaction,
            isAirtime: isAirtime,
          );
        },
        footer: (ctx) => _buildFooter(
          ttf: ttf,
          ctx: ctx,
          isWaecReg: isWaecReg,
        ),
        build: (ctx) {
          if (isAirtime) {
            return _buildAirtimePage(
              ttf: ttf,
              meta: meta!,
              transaction: transaction,
              pricePerCard: pricePerCard!,
              numberOfCards: numberOfCards!,
            );
          }
          if (isWaecReg) {
            return _buildWaecRegPage(
              ttf: ttf,
              meta: meta!,
              transaction: transaction,
              pricePerCard: pricePerCard!,
              numberOfCards: numberOfCards!,
            );
          }
          if (isWaecResult) {
            return _buildWaecResultPage(
              ttf: ttf,
              meta: meta!,
              transaction: transaction,
              pricePerCard: pricePerCard!,
              numberOfCards: numberOfCards!,
            );
          }
          return _buildGenericPage(ttf: ttf, transaction: transaction);
        },
      ),
    );

    // ── Save & share ─────────────────────────────────────────────────────────
    final dir  = await getTemporaryDirectory();
    final date = DateFormat('yyyy-MM-dd').format(transaction.createdAt);
    final file = File('${dir.path}/nexpay_receipt_$date.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      title: 'NexPay Transaction Receipt',
      text: 'Get yours → ${AppLinkHandler.appLink}',
    ));
  }

  // ── Header (page 1 only) ─────────────────────────────────────────────────
  pw.Widget _buildHeader({
    required pw.Font ttf,
    required pw.MemoryImage smallLogo,
    required TransactionModel transaction,
    required bool isAirtime,
  }) {
    final date = DateFormat('MMMM dd, yyyy hh:mm a').format(transaction.createdAt);
    final businessName = transaction.meta?.businessName;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              pw.Image(smallLogo, width: 36, height: 36),
              pw.SizedBox(width: 6),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('NexPay', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Your world of bills & gifts.', style: pw.TextStyle(fontSize: 9)),
                ],
              ),
            ]),
            pw.Text(
              isAirtime && businessName != null ? businessName : 'Transaction Receipt',
              style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 12),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                '$kNaira${kFormatter.format(transaction.amount)}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0F172A'),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(transaction.statusLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(date, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  pw.Widget _buildFooter({
    required pw.Font ttf,
    required pw.Context ctx,
    required bool isWaecReg,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (isWaecReg)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INSTRUCTION', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey)),
                  pw.Text(
                    'Go to the official WAEC e-Registration portal: waeconline.org.ng — '
                        'Click on "School Login" or "Private Candidate Registration" — '
                        'Enter your Registration Token exactly as shown — '
                        'Follow on-screen steps to complete registration.',
                    style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '©️ ${DateTime.now().year} NexPay. All rights reserved.',
                style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey),
              ),
              pw.Text(
                'Generated by NexPay | ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Page builders ────────────────────────────────────────────────────────

  List<pw.Widget> _buildAirtimePage({
    required pw.Font ttf,
    required TransactionMeta meta,
    required TransactionModel transaction,
    required double pricePerCard,
    required int numberOfCards,
  }) {
    final pins = meta.pins!;
    final serials = meta.serial ?? [];
    final network = meta.network ?? transaction.displayLabel;
    final businessName = meta.businessName ?? 'NexPay';

    return [
      pw.Column(
        children: List.generate(
          (numberOfCards / 3).ceil(),
              (row) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: List.generate(3, (col) {
              final i = row * 3 + col;
              if (i >= numberOfCards) return pw.SizedBox(width: 135);
              final pin = pins[i];
              final serial = i < serials.length ? serials[i] : null;
              return pw.Container(
                width: 135,
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      '$network $kNaira${kFormatterNo.format(pricePerCard)} Airtime',
                      style: pw.TextStyle(font: ttf, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('PIN:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      pin.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
                      style: pw.TextStyle(font: ttf, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (serial != null) ...[
                      pw.SizedBox(height: 3),
                      pw.Text('S/N: $serial', style: pw.TextStyle(font: ttf, fontSize: 6)),
                    ],
                    pw.SizedBox(height: 3),
                    pw.Divider(),
                    pw.Text(
                      'Powered by $businessName',
                      style: pw.TextStyle(font: ttf, fontSize: 6, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ];
  }

  List<pw.Widget> _buildWaecRegPage({
    required pw.Font ttf,
    required TransactionMeta meta,
    required TransactionModel transaction,
    required double pricePerCard,
    required int numberOfCards,
  }) {
    final tokens = meta.waecRegistrationTokens!;
    final schoolName = meta.schoolName ?? '';
    final date = DateFormat('MMMM dd, yyyy hh:mm a').format(transaction.createdAt);

    return [
      pw.SizedBox(height: 10),
      pw.Text('Transaction Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      ..._genericKvRows(transaction, ttf),
      pw.SizedBox(height: 16),
      pw.Text('Registration Tokens', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.GridView(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        children: List.generate(numberOfCards, (i) {
          final token = tokens[i];
          return pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(6),
            margin: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('$kNaira${kFormatterNo.format(pricePerCard)} WAEC REG',
                  style: pw.TextStyle(font: ttf, fontSize: 7, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text('TOKEN ${i + 1}:', style: pw.TextStyle(font: ttf, fontSize: 6, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  token.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
                  style: pw.TextStyle(font: ttf, fontSize: 7, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 3),
                pw.Text("NOTE: Once used can't be reused.", style: pw.TextStyle(font: ttf, fontSize: 5)),
                pw.Text('Issued: $date', style: pw.TextStyle(font: ttf, fontSize: 5), textAlign: pw.TextAlign.center),
                pw.Divider(),
                pw.Text(
                  'Powered by NexPay${schoolName.isNotEmpty ? ' — $schoolName' : ''}',
                  style: pw.TextStyle(font: ttf, fontSize: 5, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    ];
  }

  List<pw.Widget> _buildWaecResultPage({
    required pw.Font ttf,
    required TransactionMeta meta,
    required TransactionModel transaction,
    required double pricePerCard,
    required int numberOfCards,
  }) {
    final cards = meta.waecResultCards!;
    final schoolName = meta.schoolName ?? '';
    final date = DateFormat('MMMM dd, yyyy hh:mm a').format(transaction.createdAt);

    return [
      pw.SizedBox(height: 10),
      pw.Text('Transaction Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      ..._genericKvRows(transaction, ttf),
      pw.SizedBox(height: 16),
      pw.Text('Result Checker Cards', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.GridView(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        children: List.generate(numberOfCards, (i) {
          final pin    = cards[i]['Pin']?.toString() ?? '';
          final serial = cards[i]['Serial']?.toString() ?? '';
          return pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(6),
            margin: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('$kNaira${kFormatterNo.format(pricePerCard)} WAEC Result',
                  style: pw.TextStyle(font: ttf, fontSize: 7, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text('PIN ${i + 1}:', style: pw.TextStyle(font: ttf, fontSize: 6, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  pin.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
                  style: pw.TextStyle(font: ttf, fontSize: 7, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text('Serial ${i + 1}:', style: pw.TextStyle(font: ttf, fontSize: 6, fontWeight: pw.FontWeight.bold)),
                pw.Text(serial, style: pw.TextStyle(font: ttf, fontSize: 6), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 3),
                pw.Text("NOTE: Once used can't be reused.", style: pw.TextStyle(font: ttf, fontSize: 5)),
                pw.Text('Issued: $date', style: pw.TextStyle(font: ttf, fontSize: 5), textAlign: pw.TextAlign.center),
                pw.Divider(),
                pw.Text(
                  'Powered by NexPay${schoolName.isNotEmpty ? ' — $schoolName' : ''}',
                  style: pw.TextStyle(font: ttf, fontSize: 5, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    ];
  }

  List<pw.Widget> _buildGenericPage({
    required pw.Font ttf,
    required TransactionModel transaction,
  }) {
    return [
      pw.SizedBox(height: 24),
      pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 16),
      ..._genericKvRows(transaction, ttf),
      pw.SizedBox(height: 60),
      pw.Text(
        'Enjoy a better life with NexPay. Book flights, hotels, spend in foreign currencies, '
            'get virtual foreign cards, pay all your bills.',
        style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey),
      ),
    ];
  }

  /// Generic key-value rows for the PDF — works for any category.
  List<pw.Widget> _genericKvRows(TransactionModel transaction, pw.Font ttf) {
    final rows = <pw.Widget>[];

    // Always include reference
    rows.add(_kvRow('Reference', transaction.displayRef, ttf));
    rows.add(_kvRow('Category', transaction.displayLabel, ttf));

    // Dynamic metaData fields
    final fields = transaction.meta?.displayFields ?? {};
    for (final e in fields.entries) {
      final key = e.key
          .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      rows.add(_kvRow(key, e.value, ttf));
    }

    return rows;
  }

  pw.Widget _kvRow(String key, String value, pw.Font ttf) => pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(key, style: pw.TextStyle(font: ttf, fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(font: ttf, fontSize: 11)),
        ],
      ),
      pw.SizedBox(height: 10),
    ],
  );
}