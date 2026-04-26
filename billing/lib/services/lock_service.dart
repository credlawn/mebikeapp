import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LockService {
  static final LockService _instance = LockService._internal();
  late SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  // Constants
  static const int maxFailedAttempts = 5;
  static const int cooldownSeconds = 30;
  static const int backgroundLockWindowMinutes = 15;

  // Prefs keys
  static const _keyPin            = 'user_pin_hash';
  static const _keyBioEnabled     = 'biometric_enabled';
  static const _keyFailedAttempts = 'failed_attempts';
  static const _keyCooldownEnd    = 'cooldown_end_ms';
  static const _keyBackgroundedAt = 'backgrounded_at_ms';

  factory LockService() => _instance;
  LockService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── PIN ─────────────────────────────────────────────────────────────────

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  bool get isPinSet => _prefs.getString(_keyPin) != null;

  Future<void> setPin(String pin) async {
    await _prefs.setString(_keyPin, _hashPin(pin));
    await resetFailedAttempts();
  }

  bool verifyPin(String pin) {
    final stored = _prefs.getString(_keyPin);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  void clearPin() {
    _prefs.remove(_keyPin);
    _prefs.remove(_keyBioEnabled);
    _prefs.remove(_keyFailedAttempts);
    _prefs.remove(_keyCooldownEnd);
    _prefs.remove(_keyBackgroundedAt);
  }

  // ─── Failed Attempts & Cooldown ──────────────────────────────────────────

  int get failedAttempts => _prefs.getInt(_keyFailedAttempts) ?? 0;

  bool get isLockedOut {
    final cooldownEnd = _prefs.getInt(_keyCooldownEnd) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < cooldownEnd;
  }

  /// Remaining cooldown in seconds. 0 if not locked out.
  int get remainingCooldownSeconds {
    final cooldownEnd = _prefs.getInt(_keyCooldownEnd) ?? 0;
    final remaining = cooldownEnd - DateTime.now().millisecondsSinceEpoch;
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }

  Future<void> recordFailedAttempt() async {
    final attempts = failedAttempts + 1;
    await _prefs.setInt(_keyFailedAttempts, attempts);

    if (attempts >= maxFailedAttempts) {
      final cooldownEnd = DateTime.now().millisecondsSinceEpoch + (cooldownSeconds * 1000);
      await _prefs.setInt(_keyCooldownEnd, cooldownEnd);
      await _prefs.setInt(_keyFailedAttempts, 0); // Reset after lockout starts
    }
  }

  Future<void> resetFailedAttempts() async {
    await _prefs.setInt(_keyFailedAttempts, 0);
    await _prefs.remove(_keyCooldownEnd);
  }

  // ─── Background Lock ─────────────────────────────────────────────────────

  Future<void> onAppBackgrounded() async {
    await _prefs.setInt(_keyBackgroundedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> onAppForegrounded() async {
    await _prefs.remove(_keyBackgroundedAt);
  }

  bool get shouldLockOnResume {
    final backgroundedAt = _prefs.getInt(_keyBackgroundedAt);
    if (backgroundedAt == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - backgroundedAt;
    return elapsed >= (backgroundLockWindowMinutes * 60 * 1000);
  }

  // ─── Biometric ───────────────────────────────────────────────────────────

  bool get isBiometricEnabled => _prefs.getBool(_keyBioEnabled) ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_keyBioEnabled, enabled);
  }

  Future<bool> canCheckBiometrics() async {
    final canBio = await _auth.canCheckBiometrics;
    return canBio || await _auth.isDeviceSupported();
  }

  Future<bool> authenticateWithBiometrics({bool ignoreEnabledFlag = false}) async {
    if (!ignoreEnabledFlag && !isBiometricEnabled) return false;

    // Cancel any previous hanging session
    try { await _auth.stopAuthentication(); } catch (_) {}

    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to open ME BIKE',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'App Locked',
            cancelButton: 'Use PIN',
          ),
        ],
        biometricOnly: true,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Biometric Auth Error: $e');
      return false;
    }
  }
}
