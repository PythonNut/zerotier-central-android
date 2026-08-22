import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotier_central_manager/models/network_member.dart';
import 'package:zerotier_central_manager/services/central_api.dart';

void main() {
  test('sends the token only in the authorization header', () async {
    final adapter = _FakeAdapter((options) {
      expect(options.path, '/status');
      expect(options.uri.toString(), '${CentralApi.baseUrl}/status');
      expect(options.headers['authorization'], 'token secret-token-value');
      expect(options.queryParameters, isEmpty);
      return _jsonResponse({});
    });
    final api = CentralApi(
      ' secret-token-value ',
      dio: Dio()..httpClientAdapter = adapter,
    );

    await api.validateToken();
    api.close();
    expect(adapter.closed, isTrue);
  });

  test('posts an authorization update and merges a partial response', () async {
    final adapter = _FakeAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/network/8056c2e21c000001/member/abcdef0123');
      expect(
        options.uri.toString(),
        '${CentralApi.baseUrl}/network/8056c2e21c000001/member/abcdef0123',
      );
      final body = options.data is String
          ? jsonDecode(options.data as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(options.data as Map);
      expect(body, {
        'config': {'authorized': false},
      });
      return _jsonResponse({
        'config': {'authorized': false},
      });
    });
    final api = CentralApi('token', dio: Dio()..httpClientAdapter = adapter);
    final original = NetworkMember.fromJson({
      'networkId': '8056c2e21c000001',
      'nodeId': 'abcdef0123',
      'name': 'Pixel',
      'physicalAddress': '203.0.113.7/9993',
      'config': {
        'authorized': true,
        'ipAssignments': ['10.147.19.10'],
      },
    });

    final updated = await api.setAuthorized(original, false);

    expect(updated.authorized, isFalse);
    expect(updated.name, 'Pixel');
    expect(updated.zeroTierAddresses, ['10.147.19.10']);
    expect(updated.physicalAddress, '203.0.113.7/9993');
    api.close();
  });

  test('translates unauthorized responses without exposing response data', () {
    final api = CentralApi(
      'token',
      dio: Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _jsonResponse({'message': 'sensitive'}, statusCode: 401),
        ),
    );

    expect(
      api.validateToken,
      throwsA(
        isA<CentralApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              isNot(contains('sensitive')),
            ),
      ),
    );
  });
}

ResponseBody _jsonResponse(Object value, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(value),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  bool closed = false;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) => closed = true;
}
