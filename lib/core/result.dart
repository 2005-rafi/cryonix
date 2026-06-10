import 'package:flutter/foundation.dart';

@immutable
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Object error, [StackTrace? stackTrace]) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  Object? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;
  const Failure(this.error, [this.stackTrace]);
}
