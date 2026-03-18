import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  // 1. Private constructor
  NetworkService._internal();

  // 2. The single instance
  static final NetworkService _instance = NetworkService._internal();

  // 3. Factory constructor to return the same instance every time
  factory NetworkService() => _instance;

  // Global access to the status stream
  Stream<InternetStatus> get onStatusChange => InternetConnection().onStatusChange;

  // Helper to check current status once (Future)
  Future<bool> get isConnected async => await InternetConnection().hasInternetAccess;
}
