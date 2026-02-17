/// Network Utilities
/// Network-related helper functions

import 'package:connectivity_plus/connectivity_plus.dart';

/// Check if connected to network
Future<bool> isNetworkConnected() async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();

  return result != ConnectivityResult.none;
}

/// Check if connected to WiFi
Future<bool> isWiFiConnected() async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();

  return result == ConnectivityResult.wifi;
}

/// Check if connected to mobile data
Future<bool> isMobileDataConnected() async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();

  return result == ConnectivityResult.mobile;
}

/// Get connection type
Future<String> getConnectionType() async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();

  if (result == ConnectivityResult.wifi) {
    return 'WiFi';
  } else if (result == ConnectivityResult.mobile) {
    return 'Mobile';
  } else if (result == ConnectivityResult.none) {
    return 'None';
  }

  return 'Unknown';
}

/// Stream network connectivity changes
Stream<bool> onConnectivityChanged() {
  return Connectivity().onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
}

/// Retry logic for network calls
Future<T> retryNetworkCall<T>(
  Future<T> Function() call, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 1; i <= maxAttempts; i++) {
    try {
      return await call();
    } catch (e) {
      if (i == maxAttempts) {
        rethrow;
      }
      await Future.delayed(delay * i);
    }
  }
  throw Exception('Failed after $maxAttempts attempts');
}
