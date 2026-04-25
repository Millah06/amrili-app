
import 'package:iconify_flutter/icons/cib.dart';

class ListOfBanks {
  final String bankName;
  final String bankCode;
  final String bankSlug;
  final bool isActive;

  ListOfBanks({required this.bankName, required this.bankCode, required this.bankSlug, required this.isActive});

  factory ListOfBanks.fromJson(Map<String, dynamic> json) {
    return ListOfBanks(
        bankName: json['name'] ?? '',
        bankCode: json['code'] ?? '',
        bankSlug: json['slug'] ?? '',
        isActive: json['active'] ?? false
    );
  }
}