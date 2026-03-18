import 'dart:math';

import 'package:dio/dio.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/repositories/version/version_repository.dart';
import 'package:sheetopia/data/services/github/exceptions.dart';
import 'package:sheetopia/data/services/github/models/tag.dart';

class GitHubService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      // timeout between byte events not total transfer
      receiveTimeout: const Duration(seconds: 5),
      responseType: ResponseType.json,
      validateStatus: (status) => status != null,
    ),
  );

  final Uri _apiBaseUri;
  final Uri _webBaseUri;

  GitHubService({
    String apiBaseUri = "https://api.github.com",
    String webBaseUri = "https://github.com",
  }) : _apiBaseUri = Uri.parse(apiBaseUri),
       _webBaseUri = Uri.parse("https://github.com");

  Future<Iterable<GitHubTag>?> getRepositoryTags({
    required String owner,
    required String repo,
    int? pageSize,
    int? page,
  }) async {
    return _fetchList<GitHubTag>(
      "GET",
      "/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}/tags",
      GitHubTag.fromJson,
      queryParameters: {
        if (pageSize != null) "per_page": [pageSize.toString()],
        "page": [page.toString()],
      },
    );
  }

  Future<Iterable<T>?> _fetchList<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, List<String>> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final result = await _requestJson(
      method,
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
    if (result == null) return null;
    final list = result as List<dynamic>;
    return list.map((dynamic obj) => fromJson(obj as Map<String, dynamic>));
  }

  // ignore: unused_element
  Future<T?> _fetchObject<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, List<String>> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final result = await _requestJson(
      method,
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
    return fromJson(result);
  }

  Version? _currentVersion;
  Future<dynamic> _requestJson(
    String method,
    String path, {
    Map<String, List<String>> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    _currentVersion ??= await VersionRepository.getCurrentVersion();
    int maxRetries = 5;
    final url = _apiBaseUri
        .resolveUri(Uri(path: path, queryParameters: queryParameters))
        .toString();
    do {
      maxRetries--;
      Log.trace("GitHub request: $method $url");
      final response = await _dio.request(
        url,
        options: Options(
          method: method,
          headers: {
            ...headers,
            "Accept": "application/vnd.github+json",
            // https://docs.github.com/en/rest/about-the-rest-api/api-versions?apiVersion=2022-11-28#supported-api-versions
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "Sheetopia v$_currentVersion",
          },
        ),
      );
      if (response.statusCode == 429 ||
          (response.statusCode == 403 &&
              response.headers.value("x-ratelimit-remaining") == "0")) {
        Log.debug("GitHub rate limit exceeded");
        if (maxRetries == 0) {
          throw GitHubRateLimitMaxRetriesExceeded();
        }
        int? reset = int.tryParse(
          response.headers.value("x-ratelimit-reset") ?? "",
        );
        if (reset == null) {
          Log.warn(
            "GitHub invalid x-ratelimit-reset header: ${response.headers["x-ratelimit-reset"]}",
          );
          reset = 60;
        }
        final delay =
            min(0, reset * 1000 - DateTime.now().millisecondsSinceEpoch) + 1;
        Log.debug("Retrying GitHub request in $delay seconds");
        await Future.delayed(Duration(seconds: delay));
        continue;
      }
      if (response.statusCode == 304) {
        return null;
      }
      if (response.statusCode! >= 300) {
        throw GitHubUnexpectedStatusCode(response.statusCode!);
      }
      return response.data;
    } while (maxRetries > 0);
    throw GitHubRateLimitMaxRetriesExceeded();
  }

  Uri generateReleaseDownloadLink(String downloadFileName, String tag) {
    return _webBaseUri.resolveUri(
      Uri(
        pathSegments: [
          "juho05",
          "sheetopia",
          "releases",
          "download",
          tag,
          downloadFileName,
        ],
      ),
    );
  }
}
