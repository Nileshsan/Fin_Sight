import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Network Status Enumeration
enum NetworkStatus {
  online,
  offline,
  unknown,
}

/// Network Service
/// Monitors network connectivity and provides network status
class NetworkService {
  final Connectivity _connectivity;
  final Logger logger;

  NetworkService({
    Connectivity? connectivity,
    Logger? logger,
  })  : _connectivity = connectivity ?? Connectivity(),
        logger = logger ?? Logger();

  /// Check current network status
  Future<NetworkStatus> getNetworkStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result == ConnectivityResult.mobile) {
        logger.d('Network Status: Mobile connected');
        return NetworkStatus.online;
      } else if (result == ConnectivityResult.wifi) {
        logger.d('Network Status: WiFi connected');
        return NetworkStatus.online;
      } else if (result == ConnectivityResult.none) {
        logger.d('Network Status: No connection');
        return NetworkStatus.offline;
      }

      return NetworkStatus.unknown;
    } catch (e) {
      logger.e('Error checking network status', error: e);
      return NetworkStatus.unknown;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final status = await getNetworkStatus();
    return status == NetworkStatus.online;
  }

  /// Check if device is offline
  Future<bool> isOffline() async {
    final status = await getNetworkStatus();
    return status == NetworkStatus.offline;
  }

  /// Stream network status changes
  Stream<NetworkStatus> onNetworkStatusChanged() {
    return _connectivity.onConnectivityChanged.map((result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        return NetworkStatus.online;
      } else if (result == ConnectivityResult.none) {
        return NetworkStatus.offline;
      }
      return NetworkStatus.unknown;
    });
  }
}
