import 'package:flutter/foundation.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

// Top-level — required for compute()
List<String> _extractPhones(List<Contact> contacts) {
  final seen = <String>{};
  final result = <String>[];

  for (int i = 0; i < contacts.length; i++) {
    final phones = contacts[i].phones;
    for (int j = 0; j < phones.length; j++) {
      final number = phones[j].number.trim();
      if (_isValidPhone(number) && seen.add(number)) {
        result.add(number);
      }
    }
  }

  return result;
}

bool _isValidPhone(String number) {
  final digitsOnly = number.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length < 7) return false;
  if (digitsOnly.length > 15) return false;
  if (number.contains('*')) return false;
  if (number.contains('#')) return false;
  if (RegExp(r'^0+$').hasMatch(digitsOnly)) return false;
  return true;
}



class SyncContactProvider extends ChangeNotifier {
  bool _contactsLoaded = false;
  bool _contactsLoading = false;
  bool _contactsPermissionDenied = false;
  List<String> storePhones = [];

  bool get contactsLoaded => _contactsLoaded;
  bool get contactsLoading => _contactsLoading;
  bool get contactsPermissionDenied => _contactsPermissionDenied;



  Future<List<String>> loadContacts() async {
    if (_contactsLoaded || _contactsLoading) return storePhones;

    _contactsLoading = true;
    _contactsPermissionDenied = false;
    notifyListeners();

    try {
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        _contactsPermissionDenied = true;
        return [];
      }

      final t0 = DateTime.now();
      final contacts = await FastContacts.getAllContacts();
      debugPrint('⏱ getContacts: ${DateTime.now().difference(t0).inMilliseconds}ms | count: ${contacts.length}');

      final t1 = DateTime.now();
      storePhones = await compute(_extractPhones, contacts);
      debugPrint('⏱ compute: ${DateTime.now().difference(t1).inMilliseconds}ms | phones: ${storePhones.length}');

      _contactsLoaded = true;
      return storePhones;

    } on Exception catch (e, st) {
      debugPrint('loadContacts error: $e\n$st');
      return [];
    } finally {
      _contactsLoading = false;
      notifyListeners();
    }
  }

  /// Sends phones to your API in batches of 500 to avoid 413 Payload Too Large
  Future<void> syncWithApi(Future<void> Function(List<String> batch) apiCall) async {
    if (storePhones.isEmpty) return;

    const batchSize = 500;
    int batchNumber = 1;

    for (int i = 0; i < storePhones.length; i += batchSize) {
      final batch = storePhones.sublist(
        i,
        (i + batchSize > storePhones.length) ? storePhones.length : i + batchSize,
      );

      await apiCall(batch);
      debugPrint('✅ Synced batch $batchNumber — ${batch.length} numbers');
      batchNumber++;
    }
  }

  Future<List<String>> retryLoadContacts() async {
    _contactsLoaded = false;
    _contactsPermissionDenied = false;
    return loadContacts();
  }

  Future<List<String>> refreshContacts() async {
    _contactsLoaded = false;
    return loadContacts();
  }
}