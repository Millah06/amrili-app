// lib/providers/reward_provider.dart

import 'package:flutter/foundation.dart';

// import '../services/social_api_service.dart';
//
// import '../models/creator_stats_model.dart';
// import '../models/top_earner_model.dart';
//
// class RewardProvider with ChangeNotifier {
//   final SocialApiService _apiService = SocialApiService();
//
//   CreatorStats? _stats;
//   List<TopEarner> _topEarners = [];
//   bool _isLoadingStats = false;
//   bool _isLoadingLeaderboard = false;
//   String? _error;
//
//   CreatorStats? get stats => _stats;
//   List<TopEarner> get topEarners => _topEarners;
//   bool get isLoadingStats => _isLoadingStats;
//   bool get isLoadingLeaderboard => _isLoadingLeaderboard;
//   String? get error => _error;
//
//   Future<void> loadCreatorStats() async {
//     _isLoadingStats = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       final response = await _apiService.getCreatorStats();
//       _stats = CreatorStats.fromJson(response['stats']);
//     } catch (e) {
//       _error = e.toString();
//       debugPrint('Load stats error: $e');
//     } finally {
//       _isLoadingStats = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> loadLeaderboard() async {
//     _isLoadingLeaderboard = true;
//     notifyListeners();
//
//     try {
//       final earners = await _apiService.getTopEarners();
//       _topEarners = earners.map((json) => TopEarner.fromJson(json)).toList();
//     } catch (e) {
//       debugPrint('Load leaderboard error: $e');
//     } finally {
//       _isLoadingLeaderboard = false;
//       notifyListeners();
//     }
//   }
//
//   Future<Map<String, dynamic>> rewardPost(String postId, double amount) async {
//     try {
//       final response = await _apiService.rewardPost(
//         postId: postId,
//         amount: amount,
//       );
//
//       // Reload stats after rewarding
//       await loadCreatorStats();
//
//       return response;
//     } catch (e) {
//       debugPrint('Reward error: $e');
//       rethrow;
//     }
//   }
//
//   Future<Map<String, dynamic>> boostPost(String postId) async {
//     try {
//       return await _apiService.boostPost(postId);
//     } catch (e) {
//       debugPrint('Boost error: $e');
//       rethrow;
//     }
//   }
//
//   Future<Map<String, dynamic>> convertPoints(double amount) async {
//     try {
//       final response = await _apiService.convertRewardPoints(amount);
//
//       // Reload stats after conversion
//       await loadCreatorStats();
//
//       return response;
//     } catch (e) {
//       debugPrint('Convert error: $e');
//       rethrow;
//     }
//   }
// }

// lib/providers/reward_provider.dart - COMPLETE UPDATE

import '../services/social_api_service.dart';
import '../models/creator_stats_model.dart';
import '../models/top_earner_model.dart';

class RewardProvider with ChangeNotifier {
  final SocialApiService _apiService = SocialApiService();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  CreatorStats? _stats;
  List<TopEarner> _topEarners = [];
  int _coinBalance = 0;
  bool _isLoadingStats = false;
  bool _isLoadingLeaderboard = false;
  bool _isLoadingBalance = false;
  String? _error;

  CreatorStats? get stats => _stats;
  List<TopEarner> get topEarners => _topEarners;
  int get coinBalance => _coinBalance;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get isLoadingBalance => _isLoadingBalance;
  String? get error => _error;

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
    notifyListeners();

    try {
      final response = await _apiService.getCoinBalance();
      _coinBalance = response['balance'] ?? 0;
    } catch (e) {
      debugPrint('Load balance error: $e');
    } finally {
      _isLoadingBalance = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final earners = await _apiService.getTopEarners();
      _topEarners = earners.map((json) => TopEarner.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Load leaderboard error: $e');
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  // REPLACE rewardPost with sendGift
  Future<Map<String, dynamic>> sendGift({
    required String postId,
    required String giftType,
  }) async {
    try {
      final response = await _apiService.sendGift(
        postId: postId,
        giftType: giftType,
      );

      // Reload balance and stats after gifting
      await loadCoinBalance();
      await loadCreatorStats();

      return response;
    } catch (e) {
      debugPrint('Send gift error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> convertCoins(int coinAmount) async {
    try {
      final response = await _apiService.convertCoins(coinAmount);

      // Reload balance and stats after conversion
      await loadCoinBalance();
      await loadCreatorStats();

      return response;
    } catch (e) {
      debugPrint('Convert coins error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> boostPost(String postId) async {
    try {
      return await _apiService.boostPost(postId);
    } catch (e) {
      debugPrint('Boost error: $e');
      rethrow;
    }
  }
}