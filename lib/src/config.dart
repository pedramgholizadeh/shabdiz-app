/// Shabdiz backend configuration.
///
/// In production the app talks to apps.webirox.ir/shabdiz — the upstream
/// content API key lives only on that server. For local development point
/// [baseUrl] at the PHP dev server (php -S 127.0.0.1:8123 -t backend/public).
class AppConfig {
  static const String appName = 'شبدیز';
  static const String baseUrl = String.fromEnvironment(
    'SHABDIZ_API',
    defaultValue: 'https://apps.webirox.ir/shabdiz',
  );

  static Uri api(String path, [Map<String, String>? query]) => Uri.parse(
        '$baseUrl/api$path${query == null || query.isEmpty ? '' : '?' + Uri(queryParameters: query).query}',
      );
}
