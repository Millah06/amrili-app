// lib/services/dio_client.dart

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  late final Dio dio = _buildDio();

  Future<String> get _headers async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return token ?? '';
  }

  static const String baseUrl = 'https://api.amril.app';

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // connectTimeout: const Duration(seconds: 15),
        // receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json'
        },
      ),
    );

    // Inject admin headers on every single request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final id = await _headers;
          options.headers['Authorization']  = 'Bearer $id';
          handler.next(options);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );

    return dio;
  }
}