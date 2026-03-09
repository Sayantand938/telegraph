import 'exceptions.dart';

/// Result type for operations that can either succeed or fail.
/// This provides a type-safe way to handle errors without exceptions.
///
/// Example usage:
/// ```dart
/// Result<User> result = await getUser(id);
/// result.when(
///   success: (user) => print('Found: $user'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
///
/// Or using pattern matching:
/// ```dart
/// switch (result) {
///   Success(value: final user): print('Found: $user');
///   Failure(error: final error): print('Error: $error');
/// }
/// ```

sealed class Result<T> {
  const Result();

  /// Creates a success result with the given value.
  factory Result.success(T value) => Success<T>(value);

  /// Creates a failure result with the given error.
  factory Result.failure(AppException error) => Failure<T>(error);

  /// Returns true if this result is a success.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this result is a failure.
  bool get isFailure => this is Failure<T>;

  /// Returns the success value or throws if this is a failure.
  T get value {
    final success = this as Success<T>?;
    if (success == null) {
      throw StateError('Cannot get value from a failure result');
    }
    return success.value;
  }

  /// Returns the error or throws if this is a success.
  AppException get error {
    final failure = this as Failure<T>?;
    if (failure == null) {
      throw StateError('Cannot get error from a success result');
    }
    return failure.error;
  }

  /// Executes the appropriate callback based on this result.
  R when<R>({
    required R Function(T) success,
    required R Function(AppException) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    } else {
      return failure((this as Failure<T>).error);
    }
  }

  /// Executes the success callback if this is a success, otherwise returns null.
  R? maybeWhen<R>({
    required R Function(T) success,
    R? Function(AppException)? failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    } else if (failure != null) {
      return failure((this as Failure<T>).error);
    }
    return null;
  }

  /// Maps the success value to a new value, preserving the failure state.
  Result<R> map<R>(R Function(T) mapper) {
    if (this is Success<T>) {
      return Result.success(mapper((this as Success<T>).value));
    } else {
      return Result.failure((this as Failure<T>).error);
    }
  }

  /// Maps the error to a new error, preserving the success state.
  Result<T> mapError(AppException Function(AppException) mapper) {
    if (this is Failure<T>) {
      return Result.failure(mapper((this as Failure<T>).error));
    } else {
      return Result.success((this as Success<T>).value);
    }
  }

  /// Returns the success value or the provided default if this is a failure.
  T getOrElse(T Function() defaultValue) {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    } else {
      return defaultValue();
    }
  }

  @override
  String toString() {
    return when(
      success: (value) => 'Success(value: $value)',
      failure: (error) => 'Failure(error: $error)',
    );
  }
}

/// Represents a successful result with a value.
class Success<T> extends Result<T> {
  @override
  final T value;

  Success(this.value);

  @override
  String toString() => 'Success(value: $value)';
}

/// Represents a failed result with an error.
class Failure<T> extends Result<T> {
  @override
  final AppException error;

  Failure(this.error);

  @override
  String toString() => 'Failure(error: $error)';
}
