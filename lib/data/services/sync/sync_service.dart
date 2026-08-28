/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';
import 'package:sheetopia/data/services/sync/models/auth_key.dart';
import 'package:sheetopia/data/services/sync/models/datetime_converter.dart';
import 'package:sheetopia/data/services/sync/models/deleted_item.dart';
import 'package:sheetopia/data/services/sync/models/deleted_scores.dart';
import 'package:sheetopia/data/services/sync/models/deleted_setlists.dart';
import 'package:sheetopia/data/services/sync/models/deleted_tags.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/server_info.dart';
import 'package:sheetopia/data/services/sync/models/setlists.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';
import 'package:sheetopia/data/services/sync/models/update_score_result.dart';
import 'package:sheetopia/data/services/sync/models/user.dart';
import 'package:sheetopia/data/services/sync/sync_connection.dart';

typedef RemotelyDeleted = ({String id, DateTime? deletedAt});

class SyncService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      // timeout between byte events not total transfer
      receiveTimeout: const Duration(seconds: 5),
      responseType: ResponseType.json,
    ),
  );

  Future<SyncConnection> login(
    Uri baseUri, {
    required String user,
    required String password,
  }) async {
    final response = await _requestObject(
      baseUri,
      "POST",
      "login",
      AuthKeyModel.fromJson,
      authKey: null,
      data: {"user": user, "password": password},
    );
    return SyncConnection(baseUri: baseUri, authKey: response.authKey);
  }

  Future<void> logout(SyncConnection con) async {
    try {
      await _request(con.baseUri, "POST", "logout", authKey: con.authKey);
    } on UnauthenticatedException catch (_) {}
  }

  Future<String> getUser(SyncConnection con) async {
    final response = await _requestObject(
      con.baseUri,
      "GET",
      "user",
      UserModel.fromJson,
      authKey: con.authKey,
    );
    return response.user;
  }

  Future<List<TagModel>> getTags(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async {
    final tags = await _requestObject(
      con.baseUri,
      "GET",
      "tag",
      TagsModel.fromJson,
      authKey: con.authKey,
      queryParams: {
        if (changedAfter != null) "changedAfter": [changedAfter.toRFC3339()],
      },
    );
    return tags.tags;
  }

  Future<List<ScoreModel>> getScores(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async {
    final scores = await _requestObject(
      con.baseUri,
      "GET",
      "score",
      ScoresModel.fromJson,
      authKey: con.authKey,
      queryParams: {
        if (changedAfter != null) "changedAfter": [changedAfter.toRFC3339()],
      },
    );
    return scores.scores;
  }

  Future<List<SetlistModel>> getSetlists(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async {
    final setlists = await _requestObject(
      con.baseUri,
      "GET",
      "setlist",
      SetlistsModel.fromJson,
      authKey: con.authKey,
      queryParams: {
        if (changedAfter != null) "changedAfter": [changedAfter.toRFC3339()],
      },
    );
    return setlists.setlists;
  }

  Future<void> updateSetlist(
    SyncConnection con,
    String setlistId, {
    required String name,
    required List<String> scoreIds,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async {
    await _request(
      con.baseUri,
      "POST",
      "setlist/$setlistId",
      authKey: con.authKey,
      data: {
        "name": name,
        "scoreIds": scoreIds,
        "updatedAt": updatedAt.toUtc().toIso8601String(),
        if (writtenAt != null) "writtenAt": writtenAt.toRFC3339(),
      },
    );
  }

  Future<void> deleteSetlist(SyncConnection con, String setlistId) async {
    await _request(
      con.baseUri,
      "DELETE",
      "setlist/$setlistId",
      authKey: con.authKey,
    );
  }

  Future<List<RemotelyDeleted>> getDeletedSetlists(
    SyncConnection con, {
    DateTime? since,
  }) async {
    final result = await _requestObject<DeletedSetlistsModel>(
      con.baseUri,
      "GET",
      "setlist/deleted",
      DeletedSetlistsModel.fromJson,
      queryParams: {
        if (since != null) "since": [since.toRFC3339()],
      },
      authKey: con.authKey,
    );
    return _mergeDeleted(result.setlistIds, result.deletedSetlists);
  }

  List<RemotelyDeleted> _mergeDeleted(
    List<String> ids,
    List<DeletedItemModel> deleted,
  ) {
    final deletedAtById = {for (final d in deleted) d.id: d.deletedAt};
    return ids.map((id) => (id: id, deletedAt: deletedAtById[id])).toList();
  }

  Future<void> deleteTag(SyncConnection con, String tagId) async {
    await _request(con.baseUri, "DELETE", "tag/$tagId", authKey: con.authKey);
  }

  Future<void> deleteScore(SyncConnection con, String scoreId) async {
    await _request(
      con.baseUri,
      "DELETE",
      "score/$scoreId",
      authKey: con.authKey,
    );
  }

  Future<void> updateTag(
    SyncConnection con,
    String tagId, {
    required String name,
    required int color,
    required DateTime updatedAt,
    DateTime? writtenAt,
    TagType? type,
  }) async {
    await _request(
      con.baseUri,
      "POST",
      "tag/$tagId",
      authKey: con.authKey,
      data: {
        "name": name,
        "color": color,
        "updatedAt": updatedAt.toRFC3339(),
        if (writtenAt != null) "writtenAt": writtenAt.toRFC3339(),
        if (type != null) "type": type.name,
      },
    );
  }

  Future<UpdateScoreResultModel?> updateScore(
    SyncConnection con,
    String scoreId, {
    required String title,
    required DateTime metadataUpdatedAt,
    required List<String> tagIds,
    required ScoreMetadataModel metadata,
    DateTime? writtenAt,
    ScoreType? type,
  }) async {
    final data = {
      "title": title,
      "metadataUpdatedAt": metadataUpdatedAt.toRFC3339(),
      "metadata": metadata,
      "tagIds": tagIds,
      if (writtenAt != null) "writtenAt": writtenAt.toRFC3339(),
      if (type != null) "type": type.name,
    };
    if (writtenAt == null) {
      await _request(
        con.baseUri,
        "POST",
        "score/$scoreId",
        authKey: con.authKey,
        data: data,
      );
      return null;
    }
    return await _requestObject(
      con.baseUri,
      "POST",
      "score/$scoreId",
      UpdateScoreResultModel.fromJson,
      authKey: con.authKey,
      data: data,
    );
  }

  Future<List<RemotelyDeleted>> getDeletedTags(
    SyncConnection con, {
    DateTime? since,
  }) async {
    final result = await _requestObject<DeletedTagsModel>(
      con.baseUri,
      "GET",
      "tag/deleted",
      DeletedTagsModel.fromJson,
      queryParams: {
        if (since != null) "since": [since.toRFC3339()],
      },
      authKey: con.authKey,
    );
    return _mergeDeleted(result.tagIds, result.deletedTags);
  }

  Future<List<RemotelyDeleted>> getDeletedScores(
    SyncConnection con, {
    DateTime? since,
  }) async {
    final result = await _requestObject<DeletedScoresModel>(
      con.baseUri,
      "GET",
      "score/deleted",
      DeletedScoresModel.fromJson,
      queryParams: {
        if (since != null) "since": [since.toRFC3339()],
      },
      authKey: con.authKey,
    );
    return _mergeDeleted(result.scoreIds, result.deletedScores);
  }

  Future<void> downloadScoreFile(
    SyncConnection con,
    String scoreId, {
    required File target,
    required FileType fileType,
  }) async {
    final uri = _constructReqUri(
      con.baseUri,
      "score/$scoreId/file",
      queryParams: {
        "fileType": [fileType.name],
      },
    );
    try {
      await _dio.downloadUri(
        uri,
        target.path,
        deleteOnError: true,
        options: Options(
          headers: {
            "User-Agent": "sheetopia",
            "Authorization": "Bearer ${con.authKey}",
          },
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        _throwStatusException(e.response!.statusCode!, e.response?.data);
      }
      rethrow;
    }
  }

  Future<void> uploadScoreFile(
    SyncConnection con,
    String scoreId, {
    required File file,
    required DateTime updatedAt,
    required FileType fileType,
  }) async {
    final uri = _constructReqUri(
      con.baseUri,
      "score/$scoreId/file",
      queryParams: {
        "updatedAt": [updatedAt.toRFC3339()],
        "fileType": [fileType.name],
      },
    );
    final stream = file.openRead();
    try {
      await _dio.postUri(
        uri,
        data: stream,
        options: Options(
          contentType: switch (fileType) {
            FileType.pdf => "application/pdf",
          },
          headers: {
            "User-Agent": "sheetopia",
            Headers.contentLengthHeader: await file.length(),
            "Authorization": "Bearer ${con.authKey}",
          },
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        _throwStatusException(e.response!.statusCode!, e.response?.data);
      }
      rethrow;
    } finally {
      try {
        await stream.drain();
      } on FileSystemException catch (_) {
        // already closed
      }
    }
  }

  Future<ServerInfoModel> getServerInfo(Uri baseUri) async {
    return await _requestObject(
      baseUri,
      "GET",
      "info",
      ServerInfoModel.fromJson,
      authKey: null,
    );
  }

  Future<T> _requestObject<T>(
    Uri baseUri,
    String method,
    String endpointName,
    T Function(Map<String, dynamic>) fromJson, {
    required String? authKey,
    Object? data,
    Map<String, Iterable<String>> queryParams = const {},
    Map<String, String> headers = const {},
  }) async {
    final response = await _request(
      baseUri,
      method,
      endpointName,
      data: data,
      queryParams: queryParams,
      headers: headers,
      authKey: authKey,
    );
    if (response.data == null) {
      throw const InvalidResponseBody();
    }

    try {
      return fromJson(response.data!);
    } catch (e, st) {
      Log.error("Failed to parse response body of $endpointName", e: e, st: st);
      throw const InvalidResponseBody();
    }
  }

  Future<Response<Map<String, dynamic>?>> _request(
    Uri baseUri,
    String method,
    String endpointName, {
    Object? data,
    Map<String, Iterable<String>> queryParams = const {},
    Map<String, String> headers = const {},
    String? authKey,
  }) async {
    final uri = _constructReqUri(
      baseUri,
      endpointName,
      queryParams: queryParams,
    );
    final h = Map.of(headers);
    if (authKey != null) {
      h["Authorization"] = "Bearer $authKey";
    }
    h["User-Agent"] = "sheetopia";
    try {
      return await _dio.requestUri(
        uri,
        data: data,
        options: Options(method: method, headers: h),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != null) {
        _throwStatusException(e.response!.statusCode!, e.response?.data);
      }
      rethrow;
    }
  }

  Uri _constructReqUri(
    Uri baseUri,
    String endpointName, {
    Map<String, Iterable<String>> queryParams = const {},
  }) {
    String strippedPath = baseUri.path.toString();
    if (strippedPath.endsWith("/")) {
      strippedPath = strippedPath.substring(0, strippedPath.length - 1);
    }
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      userInfo: baseUri.userInfo,
      queryParameters: queryParams,
      path: "$strippedPath/api/$endpointName",
    );
  }

  void _throwStatusException(int status, Object? body) {
    switch (status) {
      case 401:
        throw const UnauthenticatedException();
      case 404:
        throw const NotFoundException();
      case 409:
        final deletedAt = body is Map<String, dynamic>
            ? body["deletedAt"]
            : null;
        if (deletedAt is String) {
          final parsed = DateTime.tryParse(deletedAt);
          if (parsed != null) throw DeletedException(parsed.toUtc());
        }
        throw const ConflictException();
      default:
        throw StatusCodeException(status);
    }
  }
}
