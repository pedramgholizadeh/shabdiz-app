import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStore);

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<void> requestOtp(String email) async {
    await _dio.post<dynamic>('/auth/request-otp', data: {'email': email});
  }

  Future<User> verifyOtp(String email, String code) async {
    final response = await _dio.post<dynamic>(
      '/auth/verify-otp',
      data: {'email': email, 'code': code},
    );
    final data = unwrapData(response);
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) throw const ApiException('توکن ورود دریافت نشد.');
    await _tokenStore.saveToken(token);
    return User.fromJson(data['user'] as Map<String, dynamic>? ?? const {});
  }

  Future<User?> me() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _dio.get<dynamic>('/me');
      return User.fromJson(unwrapData(response)['user'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokenStore.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _tokenStore.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);
