import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal [Ref] wrapper for unit tests that use [ProviderContainer].
class FakeRef implements Ref {
  FakeRef(this._container);

  final ProviderContainer _container;

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
