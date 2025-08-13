import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/helpers/helpers.dart';
import 'reachability_adapter.dart';

class ConnectivityPlus implements ReachabilityAdapter {
  @override
  Future<bool> get isReachability async {
    final Connectivity connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    final hasInternet =
        [ConnectivityResult.wifi, ConnectivityResult.mobile].contains(result);
    if (hasInternet) {
      return true;
    } else {
      throw DomainError.noInternetConnection;
    }
  }
}
