import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ApiService {

  static const String baseUrl = 'https://api.amril.app';

  Future<String> _getAuthTokenOptional() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken() ?? '';
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

  Future<Map<String, String>> get _headers async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _refreshedHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true); // force refresh
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query, optionalHeader = false}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    var res = await http.get(uri, headers: optionalHeader ? await _getOptionalHeaders() : await _headers);
    if (res.statusCode == 401 && !optionalHeader) {               // retry once with a fresh token
      res = await http.get(uri, headers: await _refreshedHeaders());
    }
    return _handle(res);
  }
// apply the same 401-retry to post/put/patch/delete

  // Future<dynamic> get(String path, {Map<String, String>? query, optionalHeader = false}) async {
  //   final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
  //   final res = await http.get(uri, headers:  optionalHeader ? await _getOptionalHeaders() : await _headers);
  //   print(res.body);
  //   return _handle(res);
  // }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool optionalHeader = false}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: optionalHeader ? await _getOptionalHeaders() : await _headers,
      body: jsonEncode(body),
    );
    print(res.body);
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers:  await _headers,
      body: jsonEncode(body),
    );
    print(res.body);
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers:  await _headers,
      body: jsonEncode(body),
    );
    print(res.body);
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers);
    print(res.body);
    return _handle(res);
  }

  Future<Map<String, dynamic>> submitIdentity(String urlPath, File imageFile, String fileCategory) async {

    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$urlPath'),
      );

      // Add your existing headers (same as createPost!)
      final headers = await _headers;
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

      if (response.statusCode == 200) {
        return responseData; // Returns URL string
      } else {
        print('expection');
        throw Exception(responseData['error'] ?? 'Upload failed');
      }

    } catch (error) {
      throw Exception('Failed to upload image: $error');
    }
  }

  Future<String> upload(String urlPath, File imageFile, String fileCategory) async {

    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$urlPath'),
      );

      // Add your existing headers (same as createPost!)
      final headers = await _headers;
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
        return responseData['imageUrl']; // Returns URL string
      } else {
        print('expection');
        throw Exception(responseData['error'] ?? 'Upload failed');
      }

    } catch (error) {
      throw Exception('Failed to upload image: $error');
    }
  }

  Future<Map<String, dynamic>> uploadWithType(
    String urlPath,
    File imageFile,
    String fileName, {
    required String type,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$urlPath'),
      );
      final headers = await _headers;
      request.headers.addAll(headers);
      request.fields['type'] = type;
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: fileName,
      ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(data);
      }
      throw Exception(data['message'] ?? 'Upload failed');
    } catch (error) {
      throw Exception('Upload failed: $error');
    }
  }

  dynamic _handle(http.Response res) {
    final body = jsonDecode(res.body);
    print(body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Request failed');
  }

  // ── PHASE 13 — verification ────────────────────────────────────────────────

  /// GET /kyc → { status: "unverified|pending|verified|rejected", submitted }
  Future<Map<String, dynamic>> getKycStatus() async {
    final res = await get('/kyc');
    return Map<String, dynamic>.from(res as Map);
  }

  /// POST /kyc/verify — synchronous BVN/NIN check. Throws (with the backend
  /// message) on invalid number / name mismatch / not-configured.
  Future<Map<String, dynamic>> verifyIdentity({
    required String method, // 'bvn' | 'nin'
    required String number,
  }) async {
    final res = await post('/kyc/verify', {'method': method, 'number': number});
    return Map<String, dynamic>.from(res as Map);
  }

  /// POST /auth/request-email-verification. Pass preview:true to just fetch the
  /// masked email without sending a code.
  Future<Map<String, dynamic>> requestEmailVerification({
    bool preview = false,
  }) async {
    final res =
    await post('/auth/request-email-verification', {'preview': preview});
    return Map<String, dynamic>.from(res as Map);
  }

  /// POST /auth/verify-email — confirm the 6-digit code.
  Future<Map<String, dynamic>> verifyEmail(String otp) async {
    final res = await post('/auth/verify-email', {'otp': otp});
    return Map<String, dynamic>.from(res as Map);
  }

}
