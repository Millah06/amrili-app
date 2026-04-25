import 'package:everywhere/features/support/api_service.dart';
import 'package:flutter/foundation.dart';

class SupportProvider extends ChangeNotifier {

  final SupportServices _service = SupportServices();


  bool _sending = false;

  bool get isSending => _sending;

  String ? supportName;
  String ? chatId;

  Future<void> init() async {
    try {
      final data = await _service.createOrGetChat();
      supportName = data['adminName'];
      chatId = data['chatId'];
    }
    catch (e){
      rethrow;
    }
  }

  /// Send an admin chat message for a specific order.
  Future<String?> sendMessage({
    required String chatId,
    required String message,
  }) async {
    _sending = true;
    notifyListeners();

    try {
      await _service.sendChatMessage(chatId: chatId, message: message);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

}