import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../globalclass/kiotapay_constants.dart';

class DioHelper {
  static final DioHelper _instance = DioHelper._internal();
  factory DioHelper() => _instance;

  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  DioHelper._internal() {
    dio.options.baseUrl = KiotaPayConstants.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("🔵 [REQUEST]");
          debugPrint("➡️ URL: ${options.uri}");
          debugPrint("➡️ Headers: ${options.headers}");
          debugPrint("➡️ Query Params: ${options.queryParameters}");
          debugPrint("➡️ Data: ${options.data}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("🟢 [RESPONSE]");
          debugPrint("✅ Status: ${response.statusCode}");
          debugPrint("✅ Data: ${response.data}");
          return handler.next(response);
        },
        onError: (DioError e, handler) {
          debugPrint("🔴 [ERROR]");
          debugPrint("❌ Status: ${e.response?.statusCode}");
          debugPrint("❌ Message: ${e.message}");
          debugPrint("❌ Data: ${e.response?.data}");
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> setAuthHeader() async {
    final token = await storage.read(key: 'token');
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    await setAuthHeader();
    return dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    await setAuthHeader();
    return dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    await setAuthHeader();
    return dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    await setAuthHeader();
    return dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}