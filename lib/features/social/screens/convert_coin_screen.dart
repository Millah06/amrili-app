// lib/features/social/screens/convert_coins_screen.dart
//
// PHASE 10 — Convert earned coins → wallet. DEDICATED SCREEN.
//
// Only EARNED coins (received as gifts) convert, and only for NG-tied accounts —
// both enforced by the backend. Purchased coins can never be converted, so this
// screen operates strictly on `reward.convertibleCoins`.

import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../components/transacrtion_pin.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../shared/utils/flush_bar_message.dart';
import '../providers/reward_provider.dart';

class ConvertCoinsScreen extends StatefulWidget {
  const ConvertCoinsScreen({super.key});

  @override
  State<ConvertCoinsScreen> createState() => _ConvertCoinsScreenState();
}

class _ConvertCoinsScreenState extends State<ConvertCoinsScreen> {
  final _controller = TextEditingController();
  int _amount = 0;
  bool _processing = false;

  static const int _minConversion = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<RewardProvider>();
      r.loadCoinBalance();
      r.loadCatalog(); // brings the conversionRate for the preview
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAmount(int v) {
    setState(() {
      _amount = v;
      _controller.text = v == 0 ? '' : v.toString();
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  Future<void> _convert(RewardProvider reward) async {
    if (_amount < _minConversion) {
      FlushBarMessage.showFlushBar(
          context: context, message:  'Minimum is $_minConversion coins',);
      return;
    }
    if (_amount > reward.convertibleCoins) {
      FlushBarMessage.showFlushBar(context: context, message: 'You only have ${reward.convertibleCoins} convertible coins');
      return;
    }
    setState(() => _processing = true);
    try {
      final res = await reward.convertCoins(_amount);
      if (mounted) {
        FlushBarMessage.showFlushBar(context: context, message: res['message'] ?? 'Converted successfully');
        _setAmount(0);
      }
    } catch (e) {
      if (mounted) FlushBarMessage.showFlushBar(context: context, message: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = context.watch<RewardProvider>();
    final rate = reward.conversionRate <= 0 ? 10 : reward.conversionRate;
    final nairaPreview = _amount / rate;

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Convert Coins', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // Region-locked accounts can't convert — explain instead of showing a dead form.
      body: !reward.canConvert ? _locked() : _form(reward, nairaPreview),
    );
  }

  Widget _locked() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.public_off_rounded, color: Colors.white38, size: 56),
          const SizedBox(height: 16),
          const Text('Conversion is for Nigerian accounts',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text(
            'Coins you receive as gifts can be converted to wallet balance on '
                'Nigeria-tied accounts. If you’re Nigerian abroad, set your home '
                'country in Settings and it will unlock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _form(RewardProvider reward, double nairaPreview) {
    final convertible = reward.convertibleCoins;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Convertible (earned) balance — NOT total coins.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VendorTheme.gold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('Convertible (earned) coins',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 26),
                  const SizedBox(width: 8),
                  Text('$convertible',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Only coins received as gifts can be converted',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Amount to convert',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          onChanged: (v) => setState(() => _amount = int.tryParse(v) ?? 0),
          decoration: InputDecoration(
            hintText: 'Enter coins (min $_minConversion)',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.stars_rounded, color: VendorTheme.gold),
            filled: true,
            fillColor: VendorTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: VendorTheme.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 12),
        // Quick chips, capped at the convertible balance.
        Wrap(
          spacing: 10,
          children: [
            for (final v in [100, 500, 1000])
              if (v <= convertible) _chip('$v', () => _setAmount(v)),
            if (convertible >= _minConversion) _chip('All ($convertible)', () => _setAmount(convertible)),
          ],
        ),
        const SizedBox(height: 20),
        // Preview — amount ÷ conversion rate.
        if (_amount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('You receive', style: TextStyle(color: Colors.white70, fontSize: 15)),
                Text('$kNaira${nairaPreview.toStringAsFixed(2)}',
                    style: const TextStyle(color: VendorTheme.primary, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (_amount >= _minConversion && _amount <= convertible && !_processing)
                ? () {
              // Cash-out moves money to the wallet → require the transaction PIN.
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                isDismissible: false,
                builder: (_) => TransactionPin(
                  onSuccess: () {
                    Navigator.pop(context);
                    _convert(reward);
                  },
                ),
              );
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: VendorTheme.primary,
              disabledBackgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _processing
                ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black))
                : const Text('Convert to Wallet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, VoidCallback onTap) => ActionChip(
    label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    backgroundColor: VendorTheme.surface,
    onPressed: onTap,
  );
}