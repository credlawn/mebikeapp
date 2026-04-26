import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';
import 'login_screen.dart';
import 'theme/app_snackbars.dart';

class PbService {
  static final PbService _instance = PbService._internal();
  late final PocketBase pb;
  late final SharedPreferences _prefs;

  factory PbService() => _instance;

  PbService._internal() {
    pb = PocketBase(ApiProvider.baseUrl);
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // 1. Load saved auth data
      final authData = _prefs.getString('pb_auth');
      if (authData != null) {
        final decoded = jsonDecode(authData);
        final token = decoded['token'] as String;
        final modelMap = decoded['model'] as Map<String, dynamic>?;

        if (modelMap != null) {
          final record = RecordModel.fromJson(modelMap);
          pb.authStore.save(token, record);
          // Sync with server in background
          _syncAuth();
        } else {
          pb.authStore.save(token, null);
        }
      }

      // 2. Setup listener to save future changes
      pb.authStore.onChange.listen((event) {
        if (pb.authStore.isValid) {
          _prefs.setString('pb_auth', jsonEncode({
            'token': pb.authStore.token,
            'model': pb.authStore.record,
          }));
        } else {
          _prefs.remove('pb_auth');
        }
      });

    } catch (e) {
      if (kDebugMode) print('❌ PbService Init Error: $e');
    }
  }

  // Global key to navigate from anywhere (like logout on session expire)
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _syncAuth() async {
    try {
      if (pb.authStore.isValid) {
        final auth = await pb.collection('users').authRefresh();
        
        // Manual check if account was disabled (in case refresh didn't fail)
        if (auth.record.getBoolValue('enable') == false) {
          forceLogout(message: 'Your account is disabled. Contact manager.');
          return;
        }
        if (auth.record.getStringValue('role').isEmpty) {
          forceLogout(message: 'Access denied. Role not assigned.');
          return;
        }
      }
    } catch (e) {
      final errorStr = e.toString();
      // Pro solution: Logout only if server explicitly asks for it via keyword
      if (errorStr.contains('[FORCED_LOGOUT]') || errorStr.contains('401') || errorStr.contains('403')) {
        String msg = 'Session expired. Please login again.';
        if (errorStr.contains('disabled')) msg = 'Your account is disabled.';
        if (errorStr.contains('not approved')) msg = 'Your account is not approved.';
        
        forceLogout(message: msg);
      }
    }
  }

  void forceLogout({String? message}) {
    logout();
    
    final context = navigatorKey.currentContext;
    if (context != null && message != null) {
      AppSnackBars.showError(context, message);
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  bool get isAuthenticated => pb.authStore.isValid;

  Future<RecordAuth> login(String email, String password) async {
    return await pb.collection('users').authWithPassword(email, password);
  }

  void logout() => pb.authStore.clear();
}
