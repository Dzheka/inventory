import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import '../models/auth_models.dart';

part 'auth_remote_datasource.g.dart';

@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) {
  return AuthRemoteDatasource(
    dio: ref.watch(apiClientProvider),
    storage: const FlutterSecureStorage(),
  );
}

class AuthRemoteDatasource {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRemoteDatasource({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  Future<TokenResponse> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final tokens = TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _storage.saveTokens(access: tokens.accessToken, refresh: tokens.refreshToken);
    return tokens;
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.clearTokens();
}
