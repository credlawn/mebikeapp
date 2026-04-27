import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline, checking }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // connectivity_plus 6.0+ returns a List<ConnectivityResult>
    if (results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    } else {
      return ConnectivityStatus.online;
    }
  });
});
