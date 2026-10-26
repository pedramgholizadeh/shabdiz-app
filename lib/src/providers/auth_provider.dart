import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  ShabdizUser? user;
  bool initialized = false;

  bool get isLoggedIn => user != null;

  Future<void> init() async {
    user = await _auth.restoreSession();
    initialized = true;
    notifyListeners();
  }

  Future<void> requestOtp(String email) => _auth.requestOtp(email);

  Future<void> verifyOtp(String email, String code) async {
    user = await _auth.verifyOtp(email, code);
    notifyListeners();
  }

  Future<void> updateProfile({String? name}) async {
    user = await _auth.updateProfile(name: name);
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    notifyListeners();
  }
}
