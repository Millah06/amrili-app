import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/core/constant/app_constants.dart';
import 'package:everywhere/services/api_service.dart';

class SupportServices {

  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createOrGetChat() async {
    try {
      final data =  await _apiService.post('/support/chats', {});
      return data;
    }
    catch(e) {
      rethrow;
    }
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      final data = await _apiService.post(
        '/support/chats/$chatId/messages',
        {'message': message},
      );
      print('🔥🔥 $data');
    }
    catch (e) {
      print('🔥🔥 $e');
    }
  }

  Stream<QuerySnapshot> messageStream(String roomId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.supportChatCollectionPath)
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

}