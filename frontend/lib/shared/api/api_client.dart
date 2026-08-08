import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class _CachedGet {
  final dynamic data;
  final String? etag;

  const _CachedGet(this.data, this.etag);
}

class ApiClient {
  late final Dio _dio;
  static const String _tokenKey = 'auth_token';
  static String? _tokenCache;
  static final Map<String, _CachedGet> _etagCache = {};
  static void Function()? onUnauthorized;
  static final ApiClient shared = ApiClient();

  ApiClient({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 20),
            validateStatus: (status) =>
                status != null && (status < 300 || status == 304),
            headers: {'Content-Type': 'application/json'},
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isProtoRequest(error.requestOptions)) {
            await clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final token = await getToken();
    final cacheKey = '${token ?? ''}|$path?${_queryKey(queryParameters)}';
    final cached = _etagCache[cacheKey];
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final options = cached?.etag == null
            ? null
            : Options(headers: {'If-None-Match': cached!.etag});
        final response = await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        );
        if (response.statusCode == 304 && cached != null) {
          return Response<dynamic>(
            requestOptions: response.requestOptions,
            statusCode: 200,
            statusMessage: 'Not Modified',
            headers: response.headers,
            data: cached.data,
            extra: response.extra,
          );
        }
        final etag = response.headers.value('etag');
        if (response.statusCode == 200 && response.data != null && etag != null) {
          _etagCache[cacheKey] = _CachedGet(response.data, etag);
        }
        return response;
      } on DioException catch (e) {
        final retryable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        if (!retryable || attempt >= 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw StateError('unreachable');
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<T> getProto<T extends pb.GeneratedMessage>(
      String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(List<int>) parse,
  }) async {
    final response = await _dio.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/x-protobuf'},
      ),
    );
    _throwForProtoStatus(response);
    return parse(_bytes(response.data));
  }

  Future<T> postProto<T extends pb.GeneratedMessage>(
    String path, {
    required List<int> data,
    required T Function(List<int>) parse,
  }) async {
    final response = await _dio.post<List<int>>(
      path,
      data: data,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Content-Type': 'application/x-protobuf',
          'Accept': 'application/x-protobuf',
        },
      ),
    );
    _throwForProtoStatus(response);
    return parse(_bytes(response.data));
  }

  /// 统一 proto/JSON 内容协商 GET（架构评审 F3）。
  ///
  /// 优先 protobuf：消息经 [parse] 解析后由 [toData] 转业务结构；
  /// 服务端不支持（401/406/415，见 [isProtoUnsupported]）时自动回退 JSON，
  /// 返回响应体 data['data']（Map 或 List，由调用方断言类型）。
  /// 收敛 sync/review repository 各方法逐份复制的回退骨架，新接口零样板。
  Future<dynamic> getData<T extends pb.GeneratedMessage>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(List<int>) parse,
    required dynamic Function(T) toData,
  }) async {
    try {
      final message = await getProto<T>(
        path,
        queryParameters: queryParameters,
        parse: parse,
      );
      return toData(message);
    } on DioException catch (e) {
      if (isProtoUnsupported(e)) {
        final response = await get(path, queryParameters: queryParameters);
        return response.data['data'];
      }
      rethrow;
    }
  }

  /// 统一 proto/JSON 内容协商 POST（架构评审 F3）。
  ///
  /// [protoData] 走 protobuf；服务端不支持时回退 [jsonData]。
  /// 语义同 [getData]。
  Future<dynamic> postData<T extends pb.GeneratedMessage>(
    String path, {
    required List<int> protoData,
    required T Function(List<int>) parse,
    required dynamic Function(T) toData,
    required Map<String, dynamic> jsonData,
  }) async {
    try {
      final message = await postProto<T>(
        path,
        data: protoData,
        parse: parse,
      );
      return toData(message);
    } on DioException catch (e) {
      if (isProtoUnsupported(e)) {
        final response = await post(path, data: jsonData);
        return response.data['data'];
      }
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  static List<int> _bytes(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return data;
    return const [];
  }

  static void _throwForProtoStatus(Response response) {
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  static bool _isProtoRequest(RequestOptions options) {
    return options.headers['Accept'] == 'application/x-protobuf' ||
        options.headers['Content-Type'] == 'application/x-protobuf';
  }

  static String _queryKey(Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return '';
    final entries = queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    return entries.join('&');
  }

  static Future<void> saveToken(String token) async {
    _tokenCache = token;
    _etagCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    if (_tokenCache != null) return _tokenCache;
    final prefs = await SharedPreferences.getInstance();
    _tokenCache = prefs.getString(_tokenKey);
    return _tokenCache;
  }

  static Future<void> clearToken() async {
    _tokenCache = null;
    _etagCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

/// proto 内容协商失败判定：401/406/415 → 服务端不支持 protobuf，回退 JSON 通道。
///
/// 收敛自 review/sync 两个 repository 各自的 `_unsupported()`（架构评审候选 1）。
bool isProtoUnsupported(DioException e) {
  return e.response?.statusCode == 401 ||
      e.response?.statusCode == 406 ||
      e.response?.statusCode == 415;
}
