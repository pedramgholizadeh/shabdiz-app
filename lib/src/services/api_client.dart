import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String code;
  final int status;
  ApiException(this.code, this.status);

  String get message {
    switch (code) {
      case 'rate_limited':
        return 'تعداد درخواست‌ها زیاد است؛ کمی بعد دوباره تلاش کنید.';
      case 'invalid_code':
        return 'کد وارد شده صحیح نیست.';
      case 'code_expired':
        return 'کد منقضی شده؛ کد جدید بگیرید.';
      case 'too_many_attempts':
        return 'تلاش‌های ناموفق زیاد بود؛ کد جدید بگیرید.';
      case 'unauthorized':
        return 'نشست شما منقضی شده؛ دوباره وارد شوید.';
      case 'email_send_failed':
        return 'ارسال ایمیل با خطا مواجه شد.';
      case 'upstream_unavailable':
        return 'سرور محتوا در دسترس نیست؛ بعداً تلاش کنید.';
      default:
        return 'خطایی رخ داد ($code)؛ دوباره تلاش کنید.';
    }
  }

  @override
  String toString() => message;
}

/// Central HTTP client: attaches the bearer token and unwraps
/// the backend's `{ "data": ... }` envelope.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;
  final http.Client _http = http.Client();

  String? get token => _token;
  set token(String? value) => _token = value;

  Future<dynamic> get(Uri uri, {Duration timeout = const Duration(seconds: 30)}) async {
    return _send(() => _http.get(uri, headers: _headers()), timeout);
  }

  Future<dynamic> post(Uri uri, Map<String, dynamic> body) async {
    return _send(
      () => _http.post(uri, headers: _headers(), body: jsonEncode(body)),
      const Duration(seconds: 30),
    );
  }

  Future<dynamic> patch(Uri uri, Map<String, dynamic> body) async {
    return _send(
      () => _http.patch(uri, headers: _headers(), body: jsonEncode(body)),
      const Duration(seconds: 30),
    );
  }

  Future<dynamic> put(Uri uri, Map<String, dynamic> body) async {
    return _send(
      () => _http.put(uri, headers: _headers(), body: jsonEncode(body)),
      const Duration(seconds: 30),
    );
  }

  Future<dynamic> delete(Uri uri) async {
    return _send(() => _http.delete(uri, headers: _headers()), const Duration(seconds: 30));
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn, Duration timeout) async {
    final res = await fn().timeout(timeout);
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException('bad_response', res.statusCode);
    }
    if (res.statusCode >= 400) {
      final code = json is Map && json['error'] is String
          ? json['error'] as String
          : 'http_${res.statusCode}';
      throw ApiException(code, res.statusCode);
    }
    return json;
  }

  /// Unwraps `{"data": X}` envelopes produced by the backend proxy.
  static dynamic unwrap(dynamic json) => json is Map && json.containsKey('data') ? json['data'] : json;
}
