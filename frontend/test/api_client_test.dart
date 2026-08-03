import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/shared/api/api_client.dart';
import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAdapter implements HttpClientAdapter {
  int calls = 0;
  Future<ResponseBody> Function(RequestOptions options, int callIndex)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    return handler!(options, calls);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  Object body, {
  int statusCode = 200,
  Map<String, String> headers = const {},
}) {
  final allHeaders = <String, List<String>>{
    'content-type': ['application/json'],
    for (final entry in headers.entries) entry.key: [entry.value],
  };
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: allHeaders,
  );
}

Dio _dio(_RecordingAdapter adapter) {
  return Dio()
    ..httpClientAdapter = adapter
    ..options.validateStatus =
        (status) => status != null && (status < 300 || status == 304);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.onUnauthorized = null;
  });

  test('saveToken persists and get attaches bearer token', () async {
    final adapter = _RecordingAdapter();
    adapter.handler = (options, _) async {
      expect(options.headers['Authorization'], 'Bearer token-a');
      return _json({'code': 200, 'message': 'success', 'data': {'ok': true}});
    };
    final client = ApiClient(dio: _dio(adapter));
    await ApiClient.saveToken('token-a');

    final response = await client.get('/decks');

    expect(response.data['data'], {'ok': true});
    expect(await ApiClient.getToken(), 'token-a');
  });

  test('clearToken removes persisted token', () async {
    await ApiClient.saveToken('token-b');

    await ApiClient.clearToken();

    expect(await ApiClient.getToken(), isNull);
  });

  test('401 clears token and triggers unauthorized callback', () async {
    final adapter = _RecordingAdapter();
    adapter.handler = (_, _) async => _json({'code': 401}, statusCode: 401);
    final client = ApiClient(dio: _dio(adapter));
    var unauthorizedCalls = 0;
    ApiClient.onUnauthorized = () => unauthorizedCalls += 1;
    await ApiClient.saveToken('token-c');

    await expectLater(client.get('/decks'), throwsA(isA<DioException>()));

    expect(unauthorizedCalls, 1);
    expect(await ApiClient.getToken(), isNull);
  });

  test('protobuf 401 does not clear token or trigger callback', () async {
    final adapter = _RecordingAdapter();
    adapter.handler = (_, _) async => ResponseBody.fromBytes(
          Uint8List(0),
          401,
          headers: {
            'content-type': ['application/x-protobuf'],
          },
        );
    final client = ApiClient(dio: _dio(adapter));
    var unauthorizedCalls = 0;
    ApiClient.onUnauthorized = () => unauthorizedCalls += 1;
    await ApiClient.saveToken('token-d');

    await expectLater(
      client.getProto<proto.SyncResponse>(
        '/sync/bootstrap',
        queryParameters: {'event_cursor': 0},
        parse: proto.SyncResponse.fromBuffer,
      ),
      throwsA(isA<DioException>()),
    );

    expect(unauthorizedCalls, 0);
    expect(await ApiClient.getToken(), 'token-d');
  });

  test('etag is sent and 304 returns cached body', () async {
    final adapter = _RecordingAdapter();
    adapter.handler = (options, callIndex) async {
      if (callIndex == 1) {
        return _json(
          {'code': 200, 'message': 'success', 'data': {'cached': true}},
          headers: {'etag': 'W/"v1"'},
        );
      }
      expect(options.headers['If-None-Match'], 'W/"v1"');
      return ResponseBody.fromString('', 304);
    };
    final client = ApiClient(dio: _dio(adapter));
    await ApiClient.saveToken('token-etag');

    final first = await client.get('/decks');
    final second = await client.get('/decks');

    expect(first.data['data'], {'cached': true});
    expect(second.data['data'], {'cached': true});
    expect(second.statusCode, 200);
    expect(adapter.calls, 2);
  });

  test('transient errors retry and non-transient errors do not', () async {
    final retryAdapter = _RecordingAdapter();
    retryAdapter.handler = (options, callIndex) async {
      if (callIndex < 3) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return _json({'code': 200, 'data': {'retried': true}});
    };
    final retryClient = ApiClient(dio: _dio(retryAdapter));
    await ApiClient.saveToken('token-retry');

    final response = await retryClient.get('/decks');

    expect(response.data['data'], {'retried': true});
    expect(retryAdapter.calls, 3);

    final badAdapter = _RecordingAdapter();
    badAdapter.handler = (_, _) async => _json({'code': 400}, statusCode: 400);
    final badClient = ApiClient(dio: _dio(badAdapter));

    await expectLater(badClient.get('/decks'), throwsA(isA<DioException>()));

    expect(badAdapter.calls, 1);
  });

  test('protobuf parses success and rejects error status', () async {
    final protoBytes = proto.SyncResponse(
        serverTime: '2025-08-02T12:00:00Z',
        user: proto.User(
          id: 'user-1',
          email: 'a@b.c',
          refreshTime: '04:00:00',
        ),
        eventCursor: Int64(7),
      )
        .writeToBuffer();
    final okAdapter = _RecordingAdapter();
    okAdapter.handler = (_, _) async => ResponseBody.fromBytes(
          Uint8List.fromList(protoBytes),
          200,
          headers: {
            'content-type': ['application/x-protobuf'],
          },
        );
    final client = ApiClient(dio: _dio(okAdapter));

    final parsed = await client.getProto<proto.SyncResponse>(
      '/sync/bootstrap',
      parse: proto.SyncResponse.fromBuffer,
    );

    expect(parsed.user.id, 'user-1');
    expect(parsed.eventCursor.toInt(), 7);

    final errorAdapter = _RecordingAdapter();
    errorAdapter.handler = (_, _) async => ResponseBody.fromBytes(
          Uint8List(0),
          400,
          headers: {
            'content-type': ['application/x-protobuf'],
          },
        );
    final errorClient = ApiClient(dio: _dio(errorAdapter));

    await expectLater(
      errorClient.getProto<proto.SyncResponse>(
        '/sync/bootstrap',
        parse: proto.SyncResponse.fromBuffer,
      ),
      throwsA(isA<DioException>()),
    );
  });
}
