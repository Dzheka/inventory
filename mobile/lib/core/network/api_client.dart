import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';

part 'api_client.g.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_TokenInterceptor(dio, ref));
  return dio;
}

class _TokenInterceptor extends Interceptor {
  final Dio _dio;
  final Ref _ref;
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  _TokenInterceptor(this._dio, this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccess = response.data['access_token'] as String;
        final newRefresh = response.data['refresh_token'] as String;
        await _storage.write(key: _accessTokenKey, value: newAccess);
        await _storage.write(key: _refreshTokenKey, value: newRefresh);

        // Retry the failed request
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await _storage.deleteAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

extension DioTokenStorage on FlutterSecureStorage {
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await write(key: _accessTokenKey, value: access);
    await write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await delete(key: _accessTokenKey);
    await delete(key: _refreshTokenKey);
  }
}
