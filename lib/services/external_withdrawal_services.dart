import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class WithdrawalApiServices {
  static const String baseUrl = 'https://api.amril.app';


  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken() ?? '';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Feed endpoints
  Future<Map<String, dynamic>> getListOfBanks() async {
    final headers = await _getHeaders();

    final uri = Uri.parse('$baseUrl/banks/list');

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch List of banks: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> resolveAccountNumber
      ({required String accountNumber, required String bankCode}) async {

    final headers = await _getHeaders();

    final uri = Uri.parse('$baseUrl/banks/resolve/$accountNumber/$bankCode');

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to resolve account: ${response.body}');
    }

  }

  // Initiate Withdrawal

  Future<Map<String, dynamic>> initiateWithdrawal({
    required String clientRequestId,
    required String amount,
    String? reason,
    required String name,
    required String bankCode,
    required String accountNumber,
    required String humanRef})  async {
    final headers = await _getHeaders();

    print('📤 Requesting transfer for: $clientRequestId $bankCode');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/banks/initiateWithdrawal'),
        headers: headers,
        body: jsonEncode({
          'clientRequestId': clientRequestId,
          'amount': amount,
          'reason': reason,
          'name' : name,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'humanRef' : humanRef,
        }),
      );
      print('📥 Download response status: ${response.statusCode}');
      print('📥 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Download data parsed successfully');
        return data;
      } else {
        print('❌ Download failed: ${response.body}');
        throw Exception('Failed to generate download: ${response.body}');
      }
    } catch (e) {
      print('❌ Download exception: $e');
      rethrow;
    }
  }

  // Save/Unsave post
  Future<void> savePost(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    await FirebaseFirestore.instance
        .collection('savedPosts')
        .doc(userId)
        .collection('posts')
        .doc(postId)
        .set({
      'postId': postId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsavePost(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    await FirebaseFirestore.instance
        .collection('savedPosts')
        .doc(userId)
        .collection('posts')
        .doc(postId)
        .delete();
  }

  Future<bool> isPostSaved(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('savedPosts')
        .doc(userId)
        .collection('posts')
        .doc(postId)
        .get();

    return doc.exists;
  }

  // Badges
  Future<Map<String, dynamic>> getUserBadges(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/users/$userId/badges'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['badges'] ?? {};
    } else {
      return {};
    }
  }

  // Profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/profile/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }

  Future<List<dynamic>> getUserPosts(String userId, {int limit = 20}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/social/profile/$userId/posts')
        .replace(queryParameters: {'limit': limit.toString()});

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['posts'] ?? [];
    } else {
      throw Exception('Failed to fetch user posts: ${response.body}');
    }
  }

  // lib/services/social_api_service.dart - REPLACE getSavedPosts

  Future<List<dynamic>> getSavedPosts({int limit = 20}) async {
    final headers = await _getHeaders();

    try {
      final uri = Uri.parse('$baseUrl/social/posts/saved')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['posts'] ?? [];
      } else {
        throw Exception('Failed to fetch saved posts: ${response.body}');
      }
    } catch (e) {
      print('Get saved posts error: $e');
      rethrow;
    }
  }

  // Follow
  Future<void> followUser(String userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/follow'),
      headers: headers,
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to follow user: ${response.body}');
    }
  }

  Future<void> unfollowUser(String userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/unfollow'),
      headers: headers,
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  // lib/services/social_api_service.dart - UPDATE deletePost method
  Future<void> deletePost(String postId, bool isRepost) async {
    final headers = await _getHeaders();

    print('🗑️ Deleting post: $postId'); // DEBUG

    final response = await http.delete(
      Uri.parse('$baseUrl/social/posts/$postId'),
      body: jsonEncode({
        'isRepost': isRepost
      }),
      headers: headers,
    );

    print('📥 Delete response: ${response.statusCode}'); // DEBUG
    print('📥 Response body: ${response.body}'); // DEBUG

    if (response.statusCode != 200) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

// Keep existing methods (createPost, likePost, commentOnPost, etc.)
// ... (from previous implementation)




  Future<String> uploadPostImage(File imageFile) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/upload'),
      );

      // Add your existing headers (same as createPost!)
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add the file (this is the multipart part)
      final multipartFile = await http.MultipartFile.fromPath(
        'image',           // Field name (must match backend)
        imageFile.path,    // File path
        filename: path.basename(imageFile.path), // Original filename
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response (same as your createPost!)
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return responseData['url']; // Returns URL string
      } else {
        throw Exception(responseData['error'] ?? 'Upload failed');
      }

    } catch (error) {
      throw Exception('Failed to upload image: $error');
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String text,
    String? imageUrl,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts'),
      headers: headers,
      body: jsonEncode({
        'text': text,
        'imageUrl': imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getFeeds({int limit = 20, String? lastPostId,}) async {
    final headers = await _getHeaders();
    final queryParams = {
      'limit': limit.toString(),
      if (lastPostId != null) 'lastPostId': lastPostId,
    };

    final uri = Uri.parse('$baseUrl/social/feed')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch feed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getFeed({int limit = 20, String? lastPostId,}) async {
    final headers = await _getHeaders();
    final queryParams = {
      'limit': limit.toString(),
      if (lastPostId != null) 'lastPostId': lastPostId,
    };

    final uri = Uri.parse('$baseUrl/social/feed')
        .replace(queryParameters: queryParams);

    print('Fetching feed from: $uri'); // DEBUG

    final response = await http.get(uri, headers: headers);

    print('Feed response status: ${response.statusCode}'); // DEBUG
    print('Feed response body: ${response.body}'); // DEBUG

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch feed: ${response.body}');
    }
  }

  Future<void> likePost(String postId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/like'),
      headers: headers,
      body: jsonEncode({'postId': postId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> commentOnPost({
    required String postId,
    required String text,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/comment'),
      headers: headers,
      body: jsonEncode({
        'postId': postId,
        'text': text,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to comment: ${response.body}');
    }
  }

  Future<List<dynamic>> getComments(String postId, {int limit = 20}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/social/posts/$postId/comments')
        .replace(queryParameters: {'limit': limit.toString()});

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['comments'] ?? [];
    } else {
      throw Exception('Failed to fetch comments: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> rewardPost({
    required String postId,
    required double amount,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rewards/reward'),
      headers: headers,
      body: jsonEncode({
        'postId': postId,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reward post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> boostPost(String postId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rewards/boost'),
      headers: headers,
      body: jsonEncode({'postId': postId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to boost post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> convertRewardPoints(double amount) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rewards/convert'),
      headers: headers,
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to convert points: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCreatorStats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/rewards/stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch stats: ${response.body}');
    }
  }

  Future<List<dynamic>> getTopEarners() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/leaderboard'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['earners'] ?? [];
    } else {
      throw Exception('Failed to fetch leaderboard: ${response.body}');
    }
  }
  // lib/services/social_api_service.dart - ADD THIS METHOD

  Future<Map<String, bool>> checkLikeStatus(List<String> postIds) async {
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/likes/check'),
        headers: headers,
        body: jsonEncode({'postIds': postIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, bool>.from(data['likeStatus'] ?? {});
      } else {
        return {};
      }
    } catch (e) {
      print('Check like status error: $e');
      return {};
    }
  }

}