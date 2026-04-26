import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LockService {
  static final LockService _instance = LockService._internal();
  late final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  factory LockService() => _instance;

  LockService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // PIN Logic
  bool get isPinSet => _prefs.getString('user_pin') != null;
  
  Future<void> setPin(String pin) async {
    await _prefs.setString('user_pin', pin);
  }

  bool verifyPin(String pin) {
    return _prefs.getString('user_pin') == pin;
  }

  void clearPin() {
    _prefs.remove('user_pin');
    _prefs.remove('biometric_enabled');
  }

  // Biometric Logic
  bool get isBiometricEnabled => _prefs.getBool('biometric_enabled') ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool('biometric_enabled', enabled);
  }

  Future<bool> canCheckBiometrics() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> authenticateWithBiometrics({bool ignoreEnabledFlag = false}) async {
    if (!ignoreEnabledFlag && !isBiometricEnabled) return false;

    // Cancel any previous hanging session before starting a new one
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
