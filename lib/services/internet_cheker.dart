import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService { 
  NetworkService._internal();
 
  static final NetworkService _instance = NetworkService._internal();
 
  factory NetworkService() => _instance;
 
  Stream<InternetStatus> get onStatusChange => InternetConnection().onStatusChange;
 
  Future<bool>  get isConnected async => await InternetConnection().hasInternetAccess;
}
