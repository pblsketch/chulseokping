import '../error/failure.dart';

/// 성공/실패를 타입으로 강제하는 Result (ARCHITECTURE §2 core/result).
/// usecase의 출력은 항상 `Result<T>` — 예외 누수 금지.
sealed class Result<S> {
  const Result();

  R fold<R>(R Function(S value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<S>(:final value) => onOk(value),
        Err<S>(:final failure) => onErr(failure),
      };

  bool get isOk => this is Ok<S>;

  S? get valueOrNull => switch (this) {
    Ok<S>(:final value) => value,
    Err<S>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Ok<S>() => null,
    Err<S>(:final failure) => failure,
  };
}

class Ok<S> extends Result<S> {
  const Ok(this.value);

  final S value;
}

class Err<S> extends Result<S> {
  const Err(this.failure);

  final Failure failure;
}
