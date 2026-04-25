import 'package:everywhere/models/transaction_model.dart';
import 'package:everywhere/services/api_service.dart';

/// Handles all transaction-related API calls.
/// Swap ApiService with any HTTP client here without touching the rest of the app.
class TransactionService {
  final _api = ApiService();

  Future<PaginatedTransactions> fetchTransactions({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (type != null) 'type': type,
    };
    final res = await _api.get('/wallet/transactions', query: q);
    return PaginatedTransactions.fromJson(res as Map<String, dynamic>);
  }

  /// Fetches the full transaction including metaData.
  Future<TransactionModel> fetchTransactionDetail(String id) async {
    final res = await _api.get('/wallet/transactions/$id');
    return TransactionModel.fromDetailJson(
      (res as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }
}