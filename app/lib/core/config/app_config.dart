abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://apps.webiro.ir/shabdiz/api',
  );

  static const webOrigin = 'https://apps.webiro.ir/shabdiz';

  static const sourceUrl =
      'https://github.com/pedramgholizadeh/shabdiz-app';

  static const releasesUrl = '$sourceUrl/releases/latest';

  static const syncInterval = Duration(seconds: 15);
}
