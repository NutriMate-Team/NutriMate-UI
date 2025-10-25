import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // result có thể là [ConnectivityResult.mobile, ConnectivityResult.wifi]
    // Nếu danh sách kết quả chỉ chứa 'none' thì là offline
    if (result.contains(ConnectivityResult.none) && result.length == 1) {
      return false;
    }
    return true;
  }
}