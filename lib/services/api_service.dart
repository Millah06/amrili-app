import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ApiService {

  static const String baseUrl = 'https://everywhere-data-app.onrender.com';

  Future<Map<String, String>> get _headers async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers);
    print(res.body);
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    print(res.body);
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers,
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

  dynamic _handle(http.Response res) {
    final body = jsonDecode(res.body);
    print(body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Request failed');
  }
}
