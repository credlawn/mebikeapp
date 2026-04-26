import 'package:flutter/foundation.dart';

class ApiProvider {
  static const String liveUrl = 'https://api.mebike.com';
  static const String devUrl = 'http://192.168.29.184:8090';

  static String get baseUrl => kDebugMode ? devUrl : liveUrl;
}
