// lib/services/social_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SocialApiService {
  static const String baseUrl = 'https://api.amril.app';


  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken() ?? '';
  }

  Future<String> _getAuthTokenOptional() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken() ?? '';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getOptionalHeaders() async {
    final token = await _getAuthTokenOptional();

    final headers = {
      'Content-Type': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Feed endpoints
  Future<Map<String, dynamic>> getForYouFeed({int limit = 20, String? lastPostId, double? lastScore,}) async {
    final headers = await _getOptionalHeaders();
    final queryParams = {
      'limit': limit.toString(),
      if (lastPostId != null) 'lastPostId': lastPostId,
      if (lastScore != null) 'lastScore': lastScore.toString(),
    };

    final uri = Uri.parse('$baseUrl/social/feed/foryou')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch For You feed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getFollowingFeed({int limit = 20, String? lastPostId,}) async {
    final headers = await _getHeaders();
    final queryParams = {
      'limit': limit.toString(),
      if (lastPostId != null) 'lastPostId': lastPostId,
    };

    final uri = Uri.parse('$baseUrl/social/feed/following')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch Following feed: ${response.body}');
    }
  }

  // View counting
  Future<Map<String, dynamic>> incrementPostView(String postId) async {
    final headers = await _getOptionalHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts/view'),
      headers: headers,
      body: jsonEncode({'postId': postId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to increment view: ${response.body}');
    }
  }

  /// Public single-post read for the /post/:id deep link.
  /// Returns the post JSON map (postToClientShape) or null if not found.
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/web/post/$postId'),
      headers: await _getOptionalHeaders(),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch post: ${response.body}');
    }
    final body = jsonDecode(response.body);
    return (body is Map && body['post'] != null)
        ? Map<String, dynamic>.from(body['post'])
        : null;
  }

  /// Public read-only profile for the /u/:handle deep link.
  Future<Map<String, dynamic>?> getPublicProfile(String userHandle) async {
    final response = await http.get(
      Uri.parse('$baseUrl/web/u/$userHandle'),
      headers: await _getOptionalHeaders(),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
    final body = jsonDecode(response.body);
    return (body is Map && body['profile'] != null)
        ? Map<String, dynamic>.from(body['profile'])
        : null;
  }

  // Reporting
  Future<void> reportPost({required String postId, required String reason, String? details,}) async {
    final headers = await _getOptionalHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/reports'),
      headers: headers,
      body: jsonEncode({
        'postId': postId,
        'reason': reason,
        'details': details,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to report post: ${response.body}');
    }
  }

  // Repost
  Future<Map<String, dynamic>> repostPost({
    required String postId,
    String? text,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/repost'),
      headers: headers,
      body: jsonEncode({
        'postId': postId,
        'text': text,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to repost: ${response.body}');
    }
  }



  // // Download
  // Future<String> generatePostDownload(String postId) async {
  //   final headers = await _getHeaders();
  //   final response = await http.post(
  //     Uri.parse('$baseUrl/social/posts/download'),
  //     headers: headers,
  //     body: jsonEncode({'postId': postId}),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     return data['imageData'];
  //   } else {
  //     throw Exception('Failed to generate download: ${response.body}');
  //   }
  // }

  // lib/services/social_api_service.dart - UPDATE generatePostDownload

  Future<Map<String, dynamic>> generatePostDownload(String postId) async {
    final headers = await _getHeaders();

    print('📤 Requesting download for post: $postId');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/download'),
        headers: headers,
        body: jsonEncode({'postId': postId}),
      ).timeout(
        const Duration(seconds: 30), // Add timeout
        onTimeout: () {
          throw Exception('Download request timed out');
        },
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

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final headers = await _getOptionalHeaders();
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

  // Future<List<dynamic>> getUserPosts(String userId, {int limit = 20}) async {
  //   final headers = await _getOptionalHeaders();
  //   final uri = Uri.parse('$baseUrl/social/profile/$userId/posts')
  //       .replace(queryParameters: {'limit': limit.toString()});
  //
  //   final response = await http.get(uri, headers: headers);
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     return data['posts'] ?? [];
  //   } else {
  //     throw Exception('Failed to fetch user posts: ${response.body}');
  //   }
  // }

  // Add this method to your existing SocialApiService class:

  /// Paginated user posts. Returns { posts: [...], hasMore: bool }
  Future<Map<String, dynamic>> getUserPostsPaginated(
      String userId, {
        String? lastPostId,
        int limit = 15,
      }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (lastPostId != null) 'lastPostId': lastPostId,
    };

    final uri =
    Uri.parse('$baseUrl/social/profile/$userId/posts').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getOptionalHeaders());
    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return {
        'posts': body['posts'] as List,
        'hasMore': body['hasMore'] ?? false,
      };
    }
    throw Exception(body['error'] ?? 'Failed to load posts');
  }

  /// Keep the old getUserPosts for any callers not yet migrated
  Future<List<dynamic>> getUserPosts(String userId) async {
    final result = await getUserPostsPaginated(userId);
    return result['posts'] as List<dynamic>;
  }

  Future<String> toggleSave(String postId) async {
    print('save😭');
    final headers = await _getOptionalHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts/$postId/save'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return data['message'];
    } else {
      print(response.body);
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }


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

    print(response.body);

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

  Future<String> uploadPostImage(File imageFile) async {
    try {
      // Create multipart request
      // final url = await api.upload('/vendor/upload/logo', imageFile, fileCategory);
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
        return responseData['urls']; // Returns URL string
      } else {
        throw Exception(responseData['error'] ?? 'Upload failed');
      }

    } catch (error) {
      throw Exception('Failed to upload image: $error');
    }
  }

  Future<List<String>> uploadPostImages(List<XFile> imageFiles) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/upload'),
      );

      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add all files under the same field name multer.array expects
      for (final imageFile in imageFiles) {
        final multipartFile = await http.MultipartFile.fromPath(
          'images',                          // ← must match multer.array('images')
          imageFile.path,
          filename: path.basename(imageFile.path),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return List<String>.from(responseData['urls']); // ← now a list
      } else {
        throw Exception(responseData['error'] ?? 'Upload failed');
      }

    } catch (error) {
      throw Exception('Failed to upload images: $error');
    }
  }

  Future<Map<String, dynamic>> createPost({required String text, List<String>? imageUrls, String? title}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/posts'),
      headers: headers,
      body: jsonEncode({
        'title' : title,
        'text': text,
        'images': imageUrls,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create post: ${response.body}');
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

  Future<Map<String, dynamic>> commentOnPost({required String postId, required String text,}) async {
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

  Future<Map<String, dynamic>> fetchComments(String postId, {int limit = 20, String? cursor}) async {
    final headers = await _getOptionalHeaders();
    final uri = Uri.parse('$baseUrl/social/posts/$postId/comments')
        .replace(queryParameters: {'limit': limit.toString(), 'cursor' : cursor });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
     return data;
    } else {
      throw Exception('Failed to fetch comments: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> rewardPost({required String postId, required double amount,}) async {
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

  Future<Map<String, dynamic>> getCoinCatalog() async {
    final headers = await _getHeaders();
    final r = await http.get(Uri.parse('$baseUrl/coins/catalog'), headers: headers);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load coin catalog');
  }

  Future<Map<String, dynamic>> verifyIapPurchase({
    required String platform, required String productId, required String token,
  }) async {
    final headers = await _getHeaders();
    final r = await http.post(Uri.parse('$baseUrl/coins/purchase/iap'),
        headers: headers,
        body: jsonEncode({'platform': platform, 'productId': productId, 'token': token}));
    if (r.statusCode == 200) return jsonDecode(r.body);
    final e = jsonDecode(r.body);
    throw Exception(e['error'] ?? 'Verification failed');
  }

  Future<Map<String, dynamic>> boostPost({required String postId, required String tier}) async {
    final headers = await _getHeaders();
    final r = await http.post(Uri.parse('$baseUrl/social/boost'),
        headers: headers, body: jsonEncode({'postId': postId, 'tier': tier}));
    if (r.statusCode == 200) return jsonDecode(r.body);
    final e = jsonDecode(r.body);
    throw Exception(e['error'] ?? 'Boost failed');
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

  Future<List<dynamic>> getTopEarners() async {
    final headers = await _getOptionalHeaders();
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


  Future<Map<String, dynamic>> sendGift({required String postId, required String giftType,}) async {
    final headers = await _getHeaders();

    print('🎁 Sending gift: $giftType to post: $postId');

    final response = await http.post(
      Uri.parse('$baseUrl/gifts/send'),
      headers: headers,
      body: jsonEncode({
        'postId': postId,
        'giftType': giftType,
      }),
    );

    print('📥 Gift response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to send gift');
    }
  }

  Future<Map<String, dynamic>> sendUserGift({required String receiverId, required String giftType}) async {
    final headers = await _getHeaders();
    final r = await http.post(Uri.parse('$baseUrl/gifts/send-user'),
        headers: headers, body: jsonEncode({'receiverId': receiverId, 'giftType': giftType}));
    if (r.statusCode == 200) return jsonDecode(r.body);
    final e = jsonDecode(r.body);
    throw Exception(e['error'] ?? 'Failed to send gift');
  }

// Get user coin balance
  Future<Map<String, dynamic>> getCoinBalance() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/coins/balance'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch coin balance');
    }
  }

// Convert coins to naira
  Future<Map<String, dynamic>> convertCoins(int coinAmount) async {
    final headers = await _getHeaders();

    print('💰 Converting $coinAmount coins');

    final response = await http.post(
      Uri.parse('$baseUrl/coins/convert'),
      headers: headers,
      body: jsonEncode({'coinAmount': coinAmount}),
    );

    print('📥 Conversion response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to convert coins');
    }
  }

// Get creator stats (already exists - just update the endpoint)
  Future<Map<String, dynamic>> getCreatorStats() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/creator/stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch creator stats');
    }
  }

  Future<List<dynamic>> getSpotlightCreators() async {
    final headers = await _getHeaders();
    final r = await http.get(Uri.parse('$baseUrl/social/spotlight/creators'), headers: headers);
    if (r.statusCode == 200) return jsonDecode(r.body)['creators'] ?? [];
    throw Exception('Failed to load creators');
  }

  Future<List<dynamic>> getSpotlightSupporters() async {
    final headers = await _getHeaders();
    final r = await http.get(Uri.parse('$baseUrl/social/spotlight/supporters'), headers: headers);
    if (r.statusCode == 200) return jsonDecode(r.body)['supporters'] ?? [];
    throw Exception('Failed to load supporters');
  }

  Future<void> setLeaderboardVisibilityCreator(bool hide) async {
    final headers = await _getHeaders();
    final r = await http.patch(Uri.parse('$baseUrl/users/me/leaderboard-visibility/creators'),
        headers: headers, body: jsonEncode({'hide': hide}));
    if (r.statusCode != 200) throw Exception('Failed to update visibility');
  }

  Future<void> setLeaderboardVisibilitySupporter(bool hide) async {
    final headers = await _getHeaders();
    final r = await http.patch(Uri.parse('$baseUrl/users/me/leaderboard-visibility/supporters'),
        headers: headers, body: jsonEncode({'hide': hide}));
    if (r.statusCode != 200) throw Exception('Failed to update visibility');
  }

}

