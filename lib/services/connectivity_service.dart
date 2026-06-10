import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/network_constants.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return debounceStream(
      _connectivity.onConnectivityChanged
          .map(_isOnline)
          .distinct(),
      NetworkConstants.connectivityDebounce,
    );
  }

  Future<bool> isCurrentlyOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      return false;
    }
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);
  }
}

/// Emits the latest value only after [duration] of silence on [source].
@visibleForTesting
Stream<T> debounceStream<T>(Stream<T> source, Duration duration) {
  Timer? timer;
  StreamSubscription<T>? subscription;
  late final StreamController<T> controller;

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (event) {
          timer?.cancel();
          timer = Timer(duration, () {
            if (!controller.isClosed) {
              controller.add(event);
            }
          });
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
        cancelOnError: false,
      );
    },
    onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    },
  );

  return controller.stream;
}
