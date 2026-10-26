import '../config.dart';
import 'api_client.dart';

enum GeoStatus { iran, blocked, unknown }

/// Pre-load gate: asks the backend what country this client's IP is in.
/// The app is licensed for Iranian IPs — a non-IR IP means the user is on
/// a VPN and we politely ask them to turn it off.
class GeoService {
  final _api = ApiClient.instance;

  Future<GeoStatus> check() async {
    try {
      final res = await _api.get(AppConfig.api('/geo'), timeout: const Duration(seconds: 12));
      if (res is Map && res['iran'] == true) return GeoStatus.iran;
      if (res is Map && res['country'] is String && (res['country'] as String).isNotEmpty) {
        return GeoStatus.blocked;
      }
      return GeoStatus.unknown;
    } catch (_) {
      return GeoStatus.unknown;
    }
  }
}
