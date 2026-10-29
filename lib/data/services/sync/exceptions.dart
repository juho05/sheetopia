/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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

class DeletedException extends StatusCodeException {
  final DateTime deletedAt;

  const DeletedException(this.deletedAt) : super(409);

  @override
  String toString() {
    return "DeletedException: deleted at $deletedAt";
  }
}

class InvalidResponseBody implements Exception {
  const InvalidResponseBody();

  @override
  String toString() {
    return "InvalidResponseBody";
  }
}

class ApiVersionMismatchException implements Exception {
  final String serverApiVersion;
  final bool serverNewer;

  const ApiVersionMismatchException(
    this.serverApiVersion, {
    required this.serverNewer,
  });

  String get message => serverNewer
      ? "The sync server requires a newer version of Sheetopia. Update the "
            "app to continue syncing."
      : "The sync server is outdated. Update the server to continue syncing.";

  @override
  String toString() {
    return "ApiVersionMismatchException: server API v$serverApiVersion";
  }
}
