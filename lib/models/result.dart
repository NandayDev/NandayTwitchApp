class Result<T, E> {
  Result({this.result, this.error});

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
