import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  final RxBool isOnline = true.obs;
  final Rx<List<ConnectivityResult>> connectionStatus =
      Rx<List<ConnectivityResult>>([]);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final List<Function()> _onConnectedCallbacks = [];
  final List<Function()> _onDisconnectedCallbacks = [];

  Future<ConnectivityService> init() async {
    final initialStatus = await _connectivity.checkConnectivity();
    _updateConnectionStatus(initialStatus);

    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    print('✅ ConnectivityService initialized - Online: ${isOnline.value}');
    return this;
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    connectionStatus.value = result;

    final wasOnline = isOnline.value;
    final nowOnline = !result.contains(ConnectivityResult.none);

    isOnline.value = nowOnline;

    print('📶 Connectivity changed: $result - Online: $nowOnline');

    if (!wasOnline && nowOnline) {
      print('🌐 Connection restored!');
      _triggerOnConnectedCallbacks();
    } else if (wasOnline && !nowOnline) {
      print('📴 Connection lost!');
      _triggerOnDisconnectedCallbacks();
    }
  }

  void _triggerOnConnectedCallbacks() {
    for (final callback in _onConnectedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('❌ Error in onConnected callback: $e');
      }
    }
  }

  void _triggerOnDisconnectedCallbacks() {
    for (final callback in _onDisconnectedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('❌ Error in onDisconnected callback: $e');
      }
    }
  }

  void onConnected(Function() callback) {
    _onConnectedCallbacks.add(callback);
  }

  void onDisconnected(Function() callback) {
    _onDisconnectedCallbacks.add(callback);
  }

  void removeOnConnected(Function() callback) {
    _onConnectedCallbacks.remove(callback);
  }

  void removeOnDisconnected(Function() callback) {
    _onDisconnectedCallbacks.remove(callback);
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return isOnline.value;
  }

  String get connectionTypeString {
    if (connectionStatus.value.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (connectionStatus.value.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (connectionStatus.value.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (connectionStatus.value.contains(ConnectivityResult.none)) {
      return 'Offline';
    }
    return 'Unknown';
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _onConnectedCallbacks.clear();
    _onDisconnectedCallbacks.clear();
    super.onClose();
  }
}
