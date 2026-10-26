import '../utils/storage_utils.dart';
import '../config.dart';
import 'api_client.dart';

/// Mirrors the local favorites file to the user's cloud account.
/// Fire-and-forget: cloud failures never break local UX.
class FavoritesSync {
  static bool get _isLoggedIn => ApiClient.instance.token != null;

  /// Push the full local list to the cloud (authoritative = local).
  static Future<void> pushLocal() async {
    if (!_isLoggedIn) return;
    try {
      final items = await StorageUtils.loadFavoritesWithTimestamp();
      await ApiClient.instance.put(AppConfig.api('/favorites'), {
        'favorites': items.map((e) => e.toJson()).toList(),
      });
    } catch (_) {/* silent */}
  }

  /// Pull cloud favorites into the local file (merge, no dedupe loss).
  static Future<void> pullAndMerge() async {
    if (!_isLoggedIn) return;
    try {
      final res = await ApiClient.instance.get(AppConfig.api('/favorites'));
      final list = res is Map && res['favorites'] is List ? res['favorites'] as List : [];
      for (final item in list) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          await StorageUtils.addToFavoritesJson(item);
        }
      }
    } catch (_) {/* silent */}
  }
}
