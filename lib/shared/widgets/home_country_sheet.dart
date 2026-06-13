// lib/shared/widgets/home_country_sheet.dart
//
// PHASE 9 — Home-country setting.
// ─────────────────────────────────────────────────────────────────────────────
// Solves the foreign-SIM diaspora case: a Nigerian in Guangzhou who registered
// with a +86 number gets country=CN and fails the NG-tied rule — locked out of
// the bills/marketplace surfaces they specifically want. This sheet lets any
// user declare their home country, which:
//
//   1. PATCHes /users/me/region  (server source of truth → User.country)
//   2. Optimistically applies via RegionProvider.applyHomeCountry (instant UI)
//   3. Refreshes UserProvider, whose ProxyProvider sync confirms the change
//
// Self-contained by design — call HomeCountrySheet.show(context) from the
// wallet's international preview, profile settings, or anywhere else.
//
// Visual language mirrors AddByPhoneNumber's sheet (0xFF0F172A surface,
// rounded 28 top, drag handle, w800 title) so it feels native to the app.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics.dart';
import '../../core/region/region_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class HomeCountrySheet extends StatefulWidget {
  const HomeCountrySheet({super.key});

  /// Canonical entry point.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeCountrySheet(),
    );
  }

  @override
  State<HomeCountrySheet> createState() => _HomeCountrySheetState();
}

class _HomeCountrySheetState extends State<HomeCountrySheet> {
  final TextEditingController _search = TextEditingController();

  bool _saving = false;
  String? _savingCode; // which row shows the spinner

  // Same country set as CountryCodePickerField (kept local so this widget has
  // zero coupling to the phone field). Nigeria pinned first deliberately —
  // the #1 reason anyone opens this sheet is to claim NG.
  static const List<Map<String, String>> _countries = [
    {'name': 'Nigeria', 'code': 'NG'},
    {'name': 'United States', 'code': 'US'},
    {'name': 'United Kingdom', 'code': 'GB'},
    {'name': 'China', 'code': 'CN'},
    {'name': 'Ghana', 'code': 'GH'},
    {'name': 'Kenya', 'code': 'KE'},
    {'name': 'South Africa', 'code': 'ZA'},
    {'name': 'India', 'code': 'IN'},
    {'name': 'Canada', 'code': 'CA'},
    {'name': 'Australia', 'code': 'AU'},
    {'name': 'Germany', 'code': 'DE'},
    {'name': 'France', 'code': 'FR'},
    {'name': 'Brazil', 'code': 'BR'},
    {'name': 'UAE', 'code': 'AE'},
    {'name': 'Saudi Arabia', 'code': 'SA'},
    {'name': 'Egypt', 'code': 'EG'},
    {'name': 'Tanzania', 'code': 'TZ'},
    {'name': 'Uganda', 'code': 'UG'},
    {'name': 'Rwanda', 'code': 'RW'},
    {'name': 'Senegal', 'code': 'SN'},
    {'name': 'Cameroon', 'code': 'CM'},
    {'name': 'Ivory Coast', 'code': 'CI'},
    {'name': 'Ethiopia', 'code': 'ET'},
    {'name': 'Pakistan', 'code': 'PK'},
    {'name': 'Bangladesh', 'code': 'BD'},
    {'name': 'Philippines', 'code': 'PH'},
    {'name': 'Indonesia', 'code': 'ID'},
    {'name': 'Malaysia', 'code': 'MY'},
    {'name': 'Singapore', 'code': 'SG'},
    {'name': 'Japan', 'code': 'JP'},
    {'name': 'Netherlands', 'code': 'NL'},
    {'name': 'Spain', 'code': 'ES'},
    {'name': 'Italy', 'code': 'IT'},
    {'name': 'Sweden', 'code': 'SE'},
  ];

  /// ISO code → flag emoji (regional indicator trick, same as the phone field).
  static String _flag(String code) => code
      .toUpperCase()
      .split('')
      .map((c) => String.fromCharCode(c.codeUnitAt(0) + 127397))
      .join();

  List<Map<String, String>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _countries;
    return _countries
        .where((c) =>
    c['name']!.toLowerCase().contains(q) ||
        c['code']!.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _select(String code, String name) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _savingCode = code;
    });

    try {
      final api = ApiService();
      // Server first — User.country is the source of truth the gate reads on
      // every future login/device.
      await api.patch('/users/me/region', {'country': code});

      if (!mounted) return;

      // Optimistic local flip (instant), then the authoritative refresh —
      // loadUser() → ProxyProvider → RegionProvider.syncFromUser confirms.
      context.read<RegionProvider>().applyHomeCountry(code);
      Analytics.I.logHomeCountrySet(code);
      // Silent refresh: no splash, just updated state when it lands.
      context.read<UserProvider>().loadUser();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Home country set to $name'),
          backgroundColor: const Color(0xFF177E85),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savingCode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update your home country. Try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .84,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle — same affordance as every other Amril sheet.
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Home country',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Living abroad? Set your home country so Amril shows the '
                  'services that matter to you — Nigerians keep bills, top-ups '
                  'and the marketplace anywhere in the world.',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            // Search — instant client-side filter, no network.
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search country',
                hintStyle:
                GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                prefixIcon:
                const Icon(Icons.search, color: Colors.white38, size: 20),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Country list — generous 52px rows (comfortable tap targets),
            // trailing spinner on the row being saved.
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  final code = c['code']!;
                  final isSavingThis = _saving && _savingCode == code;

                  return InkWell(
                    onTap: _saving ? null : () => _select(code, c['name']!),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 6),
                      child: Row(
                        children: [
                          Text(_flag(code),
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              c['name']!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isSavingThis)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF21D3ED)),
                            )
                          else
                            Text(
                              code,
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}