import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';
import '../models/user.dart';
import '../models/watch_history_item.dart';

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
    final user = User.fromJson(data['user'] as Map<String, dynamic>? ?? const {});
    await _tokenStore.saveUser(user);
    return user;
  }

  /// Guests get a real token-bearing identity server-side, so watching and
  /// progress tracking work; the account can be attached later via OTP.
  Future<User> signInAsGuest() async {
    final response = await _dio.post<dynamic>('/guest');
    final data = unwrapData(response);
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) throw const ApiException('ورود مهمان ممکن نشد.');
    await _tokenStore.saveToken(token);
    final user = User.fromJson(data['user'] as Map<String, dynamic>? ?? const {});
    await _tokenStore.saveUser(user);
    return user;
  }

  Future<User?> me() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _dio.get<dynamic>('/me');
      final user = User.fromJson(
        unwrapData(response)['user'] as Map<String, dynamic>? ?? const {},
      );
      await _tokenStore.saveUser(user);
      return user;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokenStore.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<List<WatchHistoryItem>> history() async {
    final response = await _dio.get<dynamic>('/me/history');
    final data = unwrapData(response);
    final items = data['items'];
    return [
      for (final item in (items is List ? items : const []))
        if (item is Map<String, dynamic>) WatchHistoryItem.fromJson(item),
    ];
  }

  Future<void> logout() => _tokenStore.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final watchHistoryProvider =
    FutureProvider.autoDispose<List<WatchHistoryItem>>(
  (ref) => ref.watch(authRepositoryProvider).history(),
);
