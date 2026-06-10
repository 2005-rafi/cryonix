import 'dart:async';

import 'package:cryonix/core/constants/network_constants.dart';
import 'package:cryonix/services/connectivity_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debounce blocks rapid events', () {
    fakeAsync((async) {
      final source = StreamController<bool>();
      final values = <bool>[];
      debounceStream(source.stream, NetworkConstants.connectivityDebounce)
          .listen(values.add);

      source.add(true);
      source.add(false);
      source.add(true);
      async.elapse(const Duration(milliseconds: 500));
      expect(values, isEmpty);
      async.elapse(const Duration(seconds: 3));
      expect(values, [true]);
    });
  });

  test('distinct filters consecutive duplicates', () async {
    final values = await Stream.fromIterable([true, true, false, false, true])
        .distinct()
        .toList();
    expect(values, [true, false, true]);
  });
}
