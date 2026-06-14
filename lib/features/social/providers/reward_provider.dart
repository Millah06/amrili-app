// lib/features/social/providers/reward_provider.dart
//
// PHASE 10 — coin state on the purchased/earned split. FULL REPLACEMENT.
//
// Balance is no longer a single number. The backend returns:
//   purchasedCoins   — spend-only (gift/boost). Never converts.
//   earnedCoins      — received as gifts. Convertible (NG-tied only).
//   convertibleCoins — earnedCoins if NG-tied, else 0.
//   coinBalance      — purchased + earned (what the user can SPEND in total).
//
// `coinBalance` is kept as the spendable total so existing call sites that read
// it for gifting affordability keep working unchanged.

import 'package:flutter/foundation.dart';

import '../models/spotlight_models.dart';
import '../services/social_api_service.dart';
import '../models/creator_stats_model.dart';
import '../models/top_earner_model.dart';

/// A buyable coin pack from /coins/catalog. `productId` is the store SKU (non-NG)
/// and the payment-engine entityId (NG); `nairaWallet` is the NG price.
class CoinPack {
  final String productId;
  final int coins;
  final String label;
  final double nairaWallet;
  const CoinPack({
    required this.productId,
    required this.coins,
    required this.label,
    required this.nairaWallet,
  });
  factory CoinPack.fromJson(Map<String, dynamic> j) => CoinPack(
    productId: j['productId'] ?? '',
    coins: j['coins'] ?? 0,
    label: j['label'] ?? '',
    nairaWallet: (j['nairaWallet'] ?? 0).toDouble(),
  );
}

/// A boost tier from /coins/catalog.
class BoostTier {
  final String tier;
  final int coins;
  final int hours;
  final String label;
  const BoostTier({required this.tier, required this.coins, required this.hours, required this.label});
  factory BoostTier.fromJson(Map<String, dynamic> j) => BoostTier(
    tier: j['tier'] ?? '',
    coins: j['coins'] ?? 0,
    hours: j['hours'] ?? 0,
    label: j['label'] ?? '',
  );
}

class RewardProvider with ChangeNotifier {
  final SocialApiService _apiService = SocialApiService();

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── Stats / leaderboard ─────────────────────────────────────────────────────
  CreatorStats? _stats;
  List<TopEarner> _topEarners = [];
  bool _isLoadingStats = false;
  bool _isLoadingLeaderboard = false;
  String? _error;

  CreatorStats? get stats => _stats;
  List<TopEarner> get topEarners => _topEarners;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get error => _error;

  // ── Coin balance split ──────────────────────────────────────────────────────
  int _coinBalance = 0; // spendable total = purchased + earned
  int _purchasedCoins = 0;
  int _earnedCoins = 0;
  int _convertibleCoins = 0;
  bool _canConvert = false;
  bool _isLoadingBalance = false;

  int get coinBalance => _coinBalance; // total spendable (unchanged meaning for gifting)
  int get purchasedCoins => _purchasedCoins;
  int get earnedCoins => _earnedCoins;
  int get convertibleCoins => _convertibleCoins;
  bool get canConvert => _canConvert;
  bool get isLoadingBalance => _isLoadingBalance;

  double _conversionRate = 10;
  double get conversionRate => _conversionRate;
  // inside loadCatalog(), after parsing packs/boostTiers:


  // ── Catalog ─────────────────────────────────────────────────────────────────
  List<CoinPack> _packs = [];
  List<BoostTier> _boostTiers = [];
  List<CoinPack> get packs => _packs;
  List<BoostTier> get boostTiers => _boostTiers;


// ... fields:
  List<SpotlightEntry> _topCreators = [];
  List<SpotlightEntry> _topSupporters = [];
  bool _isLoadingSpotlightCreators = false;
  bool _isLoadingSpotlightSupporters = false;
  List<SpotlightEntry> get topCreators => _topCreators;
  List<SpotlightEntry> get topSupporters => _topSupporters;
  bool get isLoadingSpotlightCreators => _isLoadingSpotlightCreators;
  bool get isLoadingSpotlightSupporters => _isLoadingSpotlightSupporters;

  Future<void> loadSpotlightCreators() async {
    _isLoadingSpotlightCreators = true; safeNotify();
    try {
      final list = await _apiService.getSpotlightCreators();
      _topCreators = list.map((e) => SpotlightEntry.fromJson(e)).toList();
    } catch (e) { debugPrint('Spotlight creators error: $e'); }
    finally { _isLoadingSpotlightCreators = false; safeNotify(); }
  }

  Future<void> loadSpotlightSupporters() async {
    _isLoadingSpotlightSupporters = true; safeNotify();
    try {
      final list = await _apiService.getSpotlightSupporters();
      _topSupporters = list.map((e) => SpotlightEntry.fromJson(e)).toList();
    } catch (e) { debugPrint('Spotlight supporters error: $e'); }
    finally { _isLoadingSpotlightSupporters = false; safeNotify(); }
  }

  Future<void> toggleLeaderboardVisibility(bool hide) async {
    await _apiService.setLeaderboardVisibility(hide);
  }

  Future<void> loadCreatorStats() async {
    _isLoadingStats = true;
    _error = null;
    safeNotify();
    try {
      final response = await _apiService.getCreatorStats();
      _stats = CreatorStats.fromJson(response['stats']);
    } catch (e) {
      _error = e.toString();
      debugPrint('Load stats error: $e');
    } finally {
      _isLoadingStats = false;
      safeNotify();
    }
  }

  Future<void> loadCoinBalance() async {
    _isLoadingBalance = true;
    safeNotify();
    try {
      final r = await _apiService.getCoinBalance();
      _purchasedCoins = r['purchasedCoins'] ?? 0;
      _earnedCoins = r['earnedCoins'] ?? 0;
      _convertibleCoins = r['convertibleCoins'] ?? 0;
      _canConvert = r['canConvert'] ?? false;
      // Spendable total: prefer purchased+earned; fall back to legacy `balance`.
      _coinBalance = r['balance'] ?? (_purchasedCoins + _earnedCoins);
    } catch (e) {
      debugPrint('Load balance error: $e');
    } finally {
      _isLoadingBalance = false;
      safeNotify();
    }
  }

  Future<void> loadLeaderboard() async {
    _isLoadingLeaderboard = true;
    safeNotify();
    try {
      final earners = await _apiService.getTopEarners();
      _topEarners = earners.map((json) => TopEarner.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Load leaderboard error: $e');
    } finally {
      _isLoadingLeaderboard = false;
      safeNotify();
    }
  }

  Future<void> loadCatalog() async {
    try {
      final r = await _apiService.getCoinCatalog();
      _packs = (r['packs'] as List? ?? []).map((e) => CoinPack.fromJson(e)).toList();
      _conversionRate = (r['conversionRate'] ?? 10).toDouble();
      _boostTiers = (r['boostTiers'] as List? ?? []).map((e) => BoostTier.fromJson(e)).toList();
      safeNotify();
    } catch (e) {
      debugPrint('Load catalog error: $e');
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendGift({required String postId, required String giftType}) async {
    try {
      final response = await _apiService.sendGift(postId: postId, giftType: giftType);
      await loadCoinBalance();
      await loadCreatorStats();
      return response;
    } catch (e) {
      debugPrint('Send gift error: $e');
      rethrow;
    }
  }

  /// Convert EARNED coins → wallet (NG-tied only; enforced by the backend).
  Future<Map<String, dynamic>> convertCoins(int coinAmount) async {
    try {
      final response = await _apiService.convertCoins(coinAmount);
      await loadCoinBalance();
      await loadCreatorStats();
      return response;
    } catch (e) {
      debugPrint('Convert coins error: $e');
      rethrow;
    }
  }

  /// Boost a post for a tier ('hour6' | 'day1' | 'day3'). Spends purchased-first.
  Future<Map<String, dynamic>> boostPost({required String postId, required String tier}) async {
    try {
      final response = await _apiService.boostPost(postId: postId, tier: tier);
      await loadCoinBalance();
      return response;
    } catch (e) {
      debugPrint('Boost error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendUserGift({required String receiverId, required String giftType}) async {
    try {
      final response = await _apiService.sendUserGift(receiverId: receiverId, giftType: giftType);
      await loadCoinBalance();
      return response;
    } catch (e) {
      debugPrint('Send user gift error: $e');
      rethrow;
    }
  }

}