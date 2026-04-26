import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import 'api_provider.dart';

class PbService {
  static final PbService _instance = PbService._internal();
  late final PocketBase pb;

  factory PbService() => _instance;

  PbService._internal() {
    pb = PocketBase(ApiProvider.baseUrl);
    if (kDebugMode) {
      print('🚀 Connected to: ${ApiProvider.baseUrl}');
    }
  }

  bool get isAuthenticated => pb.authStore.isValid;

  Future<RecordAuth> login(String email, String password) async {
    return await pb.collection('users').authWithPassword(email, password);
  }

  void logout() => pb.authStore.clear();
}
