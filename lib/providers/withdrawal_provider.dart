
import 'package:everywhere/models/list_of_banks.dart';
import 'package:everywhere/services/external_withdrawal_services.dart';
import 'package:flutter/foundation.dart';

class WithdrawalProvider with ChangeNotifier {

  final WithdrawalApiServices _apiService = WithdrawalApiServices();

  List<ListOfBanks> _banks = [];
  String _accountHolder = '';
  bool _isLoading = false;
  bool _isResolving = false;
  bool ? _invalidDetails = false;


  String? _error;

  // CACHE MANAGEMENT
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  List<ListOfBanks> get banks => _banks;
  String get accountHolder => _accountHolder;
  bool get isLoading => _isLoading;
  bool get isResolving => _isResolving;
  bool? get invalidDetails => _invalidDetails;
  String? get error => _error;

  // Check if cache is still valid
  bool get _isCacheValid {
    if (_lastLoadTime == null || _banks.isEmpty) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  Future<void> loadBank({bool refresh = false, bool force = false}) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getListOfBanks();

      final newPosts = (response['banks'] as List)
          .map((json) => ListOfBanks.fromJson(json))
          .toList();

      if (refresh) {
        _banks = newPosts;
      } else {
        _banks.addAll(newPosts);
      }

      // Update cache timestamp
      _lastLoadTime = DateTime.now();
      print('✅ Feed loaded and cached (${_banks.length} posts)');
    } catch (e) {
      _error = e.toString();
      debugPrint('Feed load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveBank({required String accountNumber, required String bankCode}) async {
    _isResolving = true;
    _error = null;
    notifyListeners();

    try {

      final response = await _apiService.resolveAccountNumber(
          accountNumber: accountNumber, bankCode: bankCode);

      print(response);

      if (!response['success']) {
        _accountHolder = response['message'];
        _invalidDetails = true;
        return;
      }

      _accountHolder = response['account']['account_name'];
      print(_accountHolder);

    } catch (e) {
      _error = e.toString();
      debugPrint('Resolve Bank Error: $e');
    } finally {
      _isResolving = false;
      notifyListeners();
    }
  }

  // Invalidate cache (call when user creates/deletes post)
  void invalidateCache() {
    _lastLoadTime = null;
    print('🗑️ Cache invalidated');
  }

  void clear() {
    _accountHolder = '';
    _isLoading = false;
    _isResolving = false;
    _invalidDetails = false;
    notifyListeners();
  }
}