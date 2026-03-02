import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricsProvider extends ChangeNotifier {
  static const _key = 'biometrics_lock_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _enabled = false;
  String? _lastError;

  String? get lastError => _lastError;

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
      final available = await _localAuth.getAvailableBiometrics();
      // Prefer fingerprint if available; otherwise any biometric counts
      final hasFingerprint = available.contains(BiometricType.fingerprint);
      final hasAny = available.isNotEmpty;
      return hasFingerprint || hasAny;
    } catch (e, st) {
      _lastError = 'canCheckBiometrics error: $e';
      debugPrint('Biometrics canCheck error: $e\n$st');
      return false;
    }
  }

  Future<bool> authenticate() async {
    _lastError = null;
    try {
      // Allow device credential fallback to improve success rate on some devices.
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: false, useErrorDialogs: true),
      );
      if (!didAuthenticate) {
        _lastError = 'Authentication not completed';
      }
      return didAuthenticate;
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('Biometrics authenticate error: $e\n$st');
      return false;
    }
  }
}
