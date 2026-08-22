import 'dart:io';

import 'package:dio/dio.dart';

import '../models/account_snapshot.dart';
import '../models/central_network.dart';
import '../models/network_member.dart';

class CentralApiException implements Exception {
  final String message;
  final int? statusCode;

  const CentralApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class CentralApi {
  static const baseUrl = 'https://api.zerotier.com/api/v1';
  final Dio _dio;

  CentralApi(String token, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 10),
              headers: {
                HttpHeaders.authorizationHeader: 'token ${token.trim()}',
                HttpHeaders.acceptHeader: 'application/json',
                HttpHeaders.contentTypeHeader: 'application/json',
              },
            ),
          );

  Future<void> validateToken() async {
    try {
      await _dio.get<Object>('/status');
    } catch (error) {
      throw _translate(error);
    }
  }

  Future<List<CentralNetwork>> listNetworks() async {
    try {
      final response = await _dio.get<Object>('/network');
      final payload = response.data;
      if (payload is! List) {
        throw const CentralApiException(
          'ZeroTier returned an unexpected network response.',
        );
      }
      final networks =
          payload
              .whereType<Map>()
              .map((network) => CentralNetwork.fromJson(_map(network)))
              .where((network) => network.id.isNotEmpty)
              .toList(growable: false)
            ..sort(
              (left, right) => left.displayName.toLowerCase().compareTo(
                right.displayName.toLowerCase(),
              ),
            );
      return networks;
    } catch (error) {
      throw _translate(error);
    }
  }

  Future<List<NetworkMember>> listMembers(String networkId) async {
    try {
      final response = await _dio.get<Object>(
        '/network/${Uri.encodeComponent(networkId)}/member',
      );
      final payload = response.data;
      if (payload is! List) {
        throw const CentralApiException(
          'ZeroTier returned an unexpected member response.',
        );
      }
      final members =
          payload
              .whereType<Map>()
              .map((member) => NetworkMember.fromJson(_map(member)))
              .where((member) => member.nodeId.isNotEmpty)
              .toList(growable: false)
            ..sort(_compareMembers);
      return members;
    } catch (error) {
      throw _translate(error);
    }
  }

  Future<AccountSnapshot> loadAccount() async {
    final networks = await listNetworks();
    final membersByNetwork = <String, List<NetworkMember>>{};

    // Legacy free accounts are limited to 20 requests per second. Loading
    // member lists sequentially keeps refreshes comfortably below that limit.
    for (final network in networks) {
      membersByNetwork[network.id] = await listMembers(network.id);
    }
    return AccountSnapshot(
      networks: networks,
      membersByNetwork: membersByNetwork,
    );
  }

  Future<NetworkMember> setAuthorized(NetworkMember member, bool authorized) {
    return _updateMember(member, {
      'config': {'authorized': authorized},
    });
  }

  Future<NetworkMember> renameMember(NetworkMember member, String name) {
    return _updateMember(member, {'name': name.trim()});
  }

  Future<NetworkMember> _updateMember(
    NetworkMember member,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Object>(
        '/network/${Uri.encodeComponent(member.networkId)}/member/'
        '${Uri.encodeComponent(member.nodeId)}',
        data: data,
      );
      final payload = response.data;
      if (payload is Map) {
        return NetworkMember.fromJson(_map(payload));
      }
      // Some compatible Legacy deployments return an empty success body.
      return member.copyWith(
        name: data['name']?.toString().trim(),
        authorized: (data['config'] as Map?)?['authorized'] as bool?,
      );
    } catch (error) {
      throw _translate(error);
    }
  }

  void close() => _dio.close(force: true);

  static int _compareMembers(NetworkMember left, NetworkMember right) {
    if (left.authorized != right.authorized) {
      return left.authorized ? 1 : -1;
    }
    final byName = left.displayName.toLowerCase().compareTo(
      right.displayName.toLowerCase(),
    );
    return byName == 0 ? left.nodeId.compareTo(right.nodeId) : byName;
  }

  static Map<String, dynamic> _map(Map<dynamic, dynamic> source) =>
      source.map((key, value) => MapEntry(key.toString(), value));

  static CentralApiException _translate(Object error) {
    if (error is CentralApiException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return CentralApiException(
          'The Legacy Central token is invalid or lacks permission.',
          statusCode: status,
        );
      }
      if (status == 404) {
        return const CentralApiException(
          'The requested ZeroTier network or member was not found.',
          statusCode: 404,
        );
      }
      if (status == 429) {
        return const CentralApiException(
          'ZeroTier rate-limited the request. Wait briefly and try again.',
          statusCode: 429,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const CentralApiException('The request timed out.');
      }
      if (error.type == DioExceptionType.connectionError) {
        return const CentralApiException(
          'Unable to reach ZeroTier Central. Check the internet connection.',
        );
      }
      return CentralApiException(
        status == null
            ? 'ZeroTier Central request failed.'
            : 'ZeroTier Central request failed (HTTP $status).',
        statusCode: status,
      );
    }
    if (error is SocketException) {
      return const CentralApiException(
        'Unable to reach ZeroTier Central. Check the internet connection.',
      );
    }
    return CentralApiException(error.toString());
  }
}
