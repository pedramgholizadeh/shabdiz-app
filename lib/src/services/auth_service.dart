import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'api_client.dart';

class ShabdizUser {
  final int id;
  final String email;
  final String name;
  final String avatar;
  ShabdizUser({required this.id, required this.email, this.name = '', this.avatar = ''});

  factory ShabdizUser.fromJson(Map<String, dynamic> j) => ShabdizUser(
        id: (j['id'] as num?)?.toInt() ?? 0,
        email: j['email'] as String? ?? '',
        name: j['name'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name, 'avatar': avatar};
}

class AuthService {
  final _api = ApiClient.instance;
  static const _tokenKey = 'shabdiz_token';
  static const _userKey = 'shabdiz_user';

  ShabdizUser? _cachedUser;

  /// Returns the saved user if a valid token exists.
  Future<ShabdizUser?> restoreSession() async {
    if (_cachedUser != null) return _cachedUser;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final raw = prefs.getString(_userKey);
    if (token == null || raw == null) return null;

    _api.token = token;
    _cachedUser = ShabdizUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cachedUser;
  }

  /// Step 1 — send the 6-digit code via Resend.
  Future<void> requestOtp(String email) async {
    await _api.post(AppConfig.api('/auth/request'), {'email': email.trim()});
  }

  /// Step 2 — verify the code and persist the session.
  Future<ShabdizUser> verifyOtp(String email, String code) async {
    final res = await _api.post(AppConfig.api('/auth/verify'), {
      'email': email.trim(),
      'code': code.trim(),
    }) as Map<String, dynamic>;

    final user = ShabdizUser.fromJson(res['user'] as Map<String, dynamic>);
    _api.token = res['token'] as String;
    _cachedUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, res['token'] as String);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<ShabdizUser> updateProfile({String? name}) async {
    final res = await _api.patch(AppConfig.api('/me'), {
      if (name != null) 'name': name,
    }) as Map<String, dynamic>;
    _cachedUser = ShabdizUser.fromJson(res['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_cachedUser!.toJson()));
    return _cachedUser!;
  }

  Future<void> logout() async {
    _cachedUser = null;
    _api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  ShabdizUser? get currentUser => _cachedUser;
}
