import '../../../services/api_service.dart';

// The gift catalog is the single source of truth in
// lib/features/social/models/gift_type.dart (GiftType.allGifts), mirrored
// 1:1 by the backend GIFT_TYPES. The chat gift picker uses it directly.

class GiftSendResult {
  GiftSendResult({required this.ok, this.error, this.insufficient = false});
  final bool ok;
  final String? error;
  final bool insufficient;
}

class GiftService {
  final _api = ApiService();

  /// Current spendable coin balance, or null on failure.
  Future<int?> getCoinBalance() async {
    try {
      final data = await _api.get('/coins/balance');
      return (data?['balance'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Send a gift to a user. Backend debits coins atomically.
  Future<GiftSendResult> sendUserGift({
    required String receiverId,
    required String giftType,
  }) async {
    try {
      await _api.post('/gifts/send-user', {
        'receiverId': receiverId,
        'giftType': giftType,
      });
      return GiftSendResult(ok: true);
    } catch (e) {
      final msg = e.toString();
      final insufficient = msg.contains('INSUFFICIENT_COINS') ||
          msg.toLowerCase().contains('not enough coins');
      return GiftSendResult(
        ok: false,
        insufficient: insufficient,
        error: insufficient ? 'Not enough coins' : 'Could not send gift',
      );
    }
  }
}
