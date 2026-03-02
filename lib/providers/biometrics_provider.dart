import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricsProvider extends ChangeNotifier {
  static const _key = 'biometrics_lock_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _enabled = false;

  bool get isEnabled => _enabled;

  BiometricsProvider() {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    _enabled = sp.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_key, value);
    _enabled = value;
    notifyListeners();
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: false),
      );
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }
}
