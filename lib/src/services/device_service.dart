import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'api_client.dart';

/// Registers this installation with the backend as a "device user".
/// Login is optional — every install is tracked per platform.
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  final _api = ApiClient.instance;
  static const _deviceIdKey = 'shabdiz_device_id';

  String? _deviceId;

  String? get deviceId => _deviceId;

  Future<String> ensureDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null) {
      final rnd = Random.secure();
      id = List.generate(16, (_) => rnd.nextInt(16).toRadixString(16)).join();
      await prefs.setString(_deviceIdKey, id);
    }
    _deviceId = id;
    return id;
  }

  Future<void> register() async {
    final id = await ensureDeviceId();
    try {
      await _api.post(AppConfig.api('/device/register'), {
        'device_id': id,
        'platform': _platform(),
        'app_version': _version(),
      });
    } catch (_) {
      // Non-fatal: the app works offline of the device registry.
    }
  }

  String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  String _version() {
    // Kept in sync with pubspec.yaml version.
    return '2.0.0';
  }
}
