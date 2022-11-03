class Result<T, E> {

  Result.successful(T result) : this._(result: result);

  Result.withError(E error) : this._(error: error);

  Result._({this.result, this.error});

  final T? result;
  final E? error;

  bool get hasError {
    return error != null;
  }

  bool get isSuccessful {
    return error == null;
  }
}

class EmptyResult<E> {
  EmptyResult.withError({this.error});

  EmptyResult.successful() {
    error = null;
  }

  late E? error;

  bool get hasError {
    return error != null;
  }
}
