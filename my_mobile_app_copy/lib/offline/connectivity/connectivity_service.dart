import 'package:connectivity_plus/connectivity_plus.dart';

typedef VoidCallback = void Function();

class ConnectivityService {
  static final _conn = Connectivity();

  static void onOnline(VoidCallback callback) {
    _conn.onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        callback();
      }
    });
  }

  static Future<bool> isOnline() async {
    final s = await _conn.checkConnectivity();
    return s != ConnectivityResult.none;
  }
}
