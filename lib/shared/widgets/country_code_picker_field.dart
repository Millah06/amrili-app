import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constraints/constants.dart';

class CountryCodePickerField extends StatefulWidget {
  final String initialCode;
  final void Function(String dialCode, String countryCode) onChanged;

  const CountryCodePickerField({
    super.key,
    this.initialCode = '+234',
    required this.onChanged,
  });

  @override
  State<CountryCodePickerField> createState() => _CountryCodePickerFieldState();
}

class _CountryCodePickerFieldState extends State<CountryCodePickerField> {
  late String _selectedDial;
  late String _selectedCode;

  static String _flag(String code) => code.toUpperCase().split('').map(
          (c) => String.fromCharCode(c.codeUnitAt(0) + 127397)).join();

  static const List<Map<String, String>> _countries = [
    {'name': 'Nigeria', 'code': 'NG', 'dial': '+234'},
    {'name': 'United States', 'code': 'US', 'dial': '+1'},
    {'name': 'United Kingdom', 'code': 'GB', 'dial': '+44'},
    {'name': 'Ghana', 'code': 'GH', 'dial': '+233'},
    {'name': 'Kenya', 'code': 'KE', 'dial': '+254'},
    {'name': 'South Africa', 'code': 'ZA', 'dial': '+27'},
    {'name': 'India', 'code': 'IN', 'dial': '+91'},
    {'name': 'Canada', 'code': 'CA', 'dial': '+1'},
    {'name': 'Australia', 'code': 'AU', 'dial': '+61'},
    {'name': 'Germany', 'code': 'DE', 'dial': '+49'},
    {'name': 'France', 'code': 'FR', 'dial': '+33'},
    {'name': 'Brazil', 'code': 'BR', 'dial': '+55'},
    {'name': 'UAE', 'code': 'AE', 'dial': '+971'},
    {'name': 'Saudi Arabia', 'code': 'SA', 'dial': '+966'},
    {'name': 'Egypt', 'code': 'EG', 'dial': '+20'},
    {'name': 'Tanzania', 'code': 'TZ', 'dial': '+255'},
    {'name': 'Uganda', 'code': 'UG', 'dial': '+256'},
    {'name': 'Rwanda', 'code': 'RW', 'dial': '+250'},
    {'name': 'Senegal', 'code': 'SN', 'dial': '+221'},
    {'name': 'Cameroon', 'code': 'CM', 'dial': '+237'},
    {'name': 'Ivory Coast', 'code': 'CI', 'dial': '+225'},
    {'name': 'Ethiopia', 'code': 'ET', 'dial': '+251'},
    {'name': 'Pakistan', 'code': 'PK', 'dial': '+92'},
    {'name': 'Bangladesh', 'code': 'BD', 'dial': '+880'},
    {'name': 'Philippines', 'code': 'PH', 'dial': '+63'},
    {'name': 'Indonesia', 'code': 'ID', 'dial': '+62'},
    {'name': 'Malaysia', 'code': 'MY', 'dial': '+60'},
    {'name': 'Singapore', 'code': 'SG', 'dial': '+65'},
    {'name': 'Japan', 'code': 'JP', 'dial': '+81'},
    {'name': 'China', 'code': 'CN', 'dial': '+86'},
    {'name': 'Netherlands', 'code': 'NL', 'dial': '+31'},
    {'name': 'Spain', 'code': 'ES', 'dial': '+34'},
    {'name': 'Italy', 'code': 'IT', 'dial': '+39'},
    {'name': 'Sweden', 'code': 'SE', 'dial': '+46'},
    {'name': 'Norway', 'code': 'NO', 'dial': '+47'},
    {'name': 'Switzerland', 'code': 'CH', 'dial': '+41'},
    {'name': 'Mexico', 'code': 'MX', 'dial': '+52'},
    {'name': 'Argentina', 'code': 'AR', 'dial': '+54'},
    {'name': 'Colombia', 'code': 'CO', 'dial': '+57'},
    {'name': 'New Zealand', 'code': 'NZ', 'dial': '+64'},
    {'name': 'Turkey', 'code': 'TR', 'dial': '+90'},
    {'name': 'Israel', 'code': 'IL', 'dial': '+972'},
    {'name': 'Portugal', 'code': 'PT', 'dial': '+351'},
    {'name': 'Ireland', 'code': 'IE', 'dial': '+353'},
    {'name': 'Poland', 'code': 'PL', 'dial': '+48'},
    {'name': 'Ukraine', 'code': 'UA', 'dial': '+380'},
    {'name': 'Zimbabwe', 'code': 'ZW', 'dial': '+263'},
    {'name': 'Zambia', 'code': 'ZM', 'dial': '+260'},
    {'name': 'Morocco', 'code': 'MA', 'dial': '+212'},
    {'name': 'Algeria', 'code': 'DZ', 'dial': '+213'},
    {'name': 'Somalia', 'code': 'SO', 'dial': '+252'},
    {'name': 'Sudan', 'code': 'SD', 'dial': '+249'},
    {'name': 'Angola', 'code': 'AO', 'dial': '+244'},
    {'name': 'Mozambique', 'code': 'MZ', 'dial': '+258'},
  ];

  @override
  void initState() {
    super.initState();
    final initial = _countries.firstWhere(
          (c) => c['dial'] == widget.initialCode,
      orElse: () => _countries.first,
    );
    _selectedDial = initial['dial']!;
    _selectedCode = initial['code']!;
  }

  void _openPicker() {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = _countries
              .where((c) =>
          c['name']!.toLowerCase().contains(query.toLowerCase()) ||
              c['dial']!.contains(query))
              .toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: TextField(
                    autofocus: true,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: kButtonColor,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white38, size: 20),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final isSelected = c['code'] == _selectedCode;
                      return ListTile(
                        leading: Text(_flag(c['code']!),
                            style: const TextStyle(fontSize: 24)),
                        title: Text(c['name']!,
                            style: GoogleFonts.inter(
                              color: isSelected ? kButtonColor : Colors.white,
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            )),
                        trailing: Text(c['dial']!,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 13.5,
                            )),
                        onTap: () {
                          setState(() {
                            _selectedDial = c['dial']!;
                            _selectedCode = c['code']!;
                          });
                          widget.onChanged(_selectedDial, _selectedCode);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_flag(_selectedCode), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(_selectedDial,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}