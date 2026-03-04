import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricsProvider extends ChangeNotifier {
  static const _key = 'biometrics_lock_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _shouldLock = false;
  bool _enabled = false;
  String? _lastError;
  int _failedAttempts = 0;
  bool _permanentlyLocked = false;

  bool get shouldLock => _shouldLock;
  String? get lastError => _lastError;
  int get failedAttempts => _failedAttempts;
  bool get permanentlyLocked => _permanentlyLocked;
  bool get isEnabled => _enabled;

  // Future that resolves when SharedPreferences load is complete
  late final Future<void> ready;

  BiometricsProvider() {
    ready = _load();
  }

  /// Mark app as needing lock (on pause)
  void markAppLocked() {
    _shouldLock = true;
    notifyListeners();
  }

  /// Unlock app after successful authentication
  void markUnlocked() {
    _shouldLock = false;
    _failedAttempts = 0;
    _permanentlyLocked = false;
    notifyListeners();
  }

  /// Load enabled state from SharedPreferences
  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    _enabled = sp.getBool(_key) ?? false;

    // Lock on startup only if enabled
    _shouldLock = _enabled;

    _failedAttempts = 0;
    _permanentlyLocked = false;

    notifyListeners();
  }

  /// Enable or disable biometrics
  Future<void> setEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_key, value);
    _enabled = value;
    _shouldLock = value; // update lock state
    notifyListeners();
  }

  /// Check if any biometric is available
  Future<bool> canCheckBiometrics() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      final hasFingerprint = available.contains(BiometricType.fingerprint);
      final hasAny = available.isNotEmpty;
      return hasFingerprint || hasAny;
    } catch (e, st) {
      _lastError = 'canCheckBiometrics error: $e';
      debugPrint('Biometrics canCheck error: $e\n$st');
      return false;
    }
  }

  /// Authenticate user via biometrics
  Future<bool> authenticate() async {
    _lastError = null;
    try {
      if (_permanentlyLocked) {
        _lastError = 'Permanently locked due to too many failed attempts';
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        _failedAttempts = 0;
        markUnlocked();
        return true;
      }

      // failed attempt
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _permanentlyLocked = true;
        _lastError = 'Too many failed attempts. Please close and reopen the app.';
      } else {
        _lastError = 'Authentication not completed';
      }
      notifyListeners();
      return false;
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('Biometrics authenticate error: $e\n$st');

      // increment failed attempts on unexpected errors as safety
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _permanentlyLocked = true;
        _lastError = 'Too many failed attempts. Please close and reopen the app.';
      }
      notifyListeners();
      return false;
    }
  }
}