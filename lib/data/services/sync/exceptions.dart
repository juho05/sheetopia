class StatusCodeException implements Exception {
  final int code;

  const StatusCodeException(this.code);

  @override
  String toString() {
    return "StatusCodeException: $code";
  }
}

class UnauthenticatedException extends StatusCodeException {
  const UnauthenticatedException() : super(401);
}

class NotFoundException extends StatusCodeException {
  const NotFoundException() : super(404);
}

class ConflictException extends StatusCodeException {
  const ConflictException() : super(409);
}

class InvalidResponseBody implements Exception {
  const InvalidResponseBody();
  @override
  String toString() {
    return "InvalidResponseBody";
  }
}
