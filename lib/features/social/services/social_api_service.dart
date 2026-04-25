// lib/services/social_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everywhere/features/social/models/comment_model.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SocialApiService {
  static const String baseUrl = 'https://everywhere-data-app.onrender.com'; // Replace with your Render URL


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
  Future<Map<String, dynamic>> getForYouFeed({
    int limit = 20,
    String? lastPostId,
    double? lastScore,
  }) async {
    final headers = await _getHeaders();
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

  Future<Map<String, dynamic>> getFollowingFeed({
    int limit = 20,
    String? lastPostId,
  }) async {
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
    final headers = await _getHeaders();
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

  // Reporting
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    final headers = await _getHeaders();
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

  Future<int> getRepostCount(String postId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/posts/$postId/reposts'),
      headers: headers,
    );

    print('This is the post id $postId ');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      return 0;
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

// Keep existing methods (createPost, likePost, commentOnPost, etc.)
// ... (from previous implementation)




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

  Future<Map<String, dynamic>> createPost({
    required String text,
    List<String>? imageUrls,
    String? title
  }) async {
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

  Future<Map<String, dynamic>> fetchComments(String postId, {int limit = 20, String? cursor}) async {
    final headers = await _getHeaders();
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

