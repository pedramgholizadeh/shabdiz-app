import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/session.dart';
import '../storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // An expired or revoked token must not strand the user: drop it so
        // the next launch starts fresh (as guest or at the login screen).
        if (error.response?.statusCode == 401) {
          await tokenStore.clear();
          ref.read(currentUserProvider.notifier).set(null);
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

Map<String, dynamic> unwrapData(Response<dynamic> response) {
  final body = response.data;
  if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
    return body['data'] as Map<String, dynamic>;
  }
  throw const ApiException('پاسخ نامعتبر از سرور دریافت شد.');
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String apiErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final message = (data['error'] as Map<String, dynamic>)['message'];
      if (message != null) return message.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'اتصال به سرور برقرار نشد. اینترنت خود را بررسی کنید.';
    }
  }
  return 'خطای نامشخصی رخ داد. دوباره تلاش کنید.';
}
