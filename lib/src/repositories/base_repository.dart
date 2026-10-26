import 'dart:convert';
import '../config.dart';
import '../services/api_client.dart';

/// All content requests go through the Shabdiz backend proxy
/// (apps.webiro.ir/shabdiz). The upstream API key never ships with the app.
class BaseRepository {
  static const List<String> _legacyHelperServers = []; // kept for API compat

  String get apiKey => ''; // upstream key lives server-side now
  String get baseUrl => AppConfig.baseUrl;
  List<String> get helperServers => _legacyHelperServers;

  /// GET a proxied endpoint and return the unwrapped `data` payload as raw JSON.
  Future<String> executeRequest(String relativePathAndQuery) async {
    final json = await ApiClient.instance.get(
      AppConfig.api(relativePathAndQuery),
      timeout: const Duration(seconds: 40),
    );
    final data = ApiClient.unwrap(json);
    return jsonEncode(data);
  }
}
