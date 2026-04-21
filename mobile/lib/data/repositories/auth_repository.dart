import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(authRemoteDatasourceProvider));
}

class AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepository(this._datasource);

  Future<({UserEntity user, String error})> login(
      String username, String password) async {
    try {
      await _datasource.login(username, password);
      final user = await _datasource.getMe();
      return (user: user as UserEntity, error: '');
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ??
          e.message ??
          'Network error';
      return (user: _emptyUser, error: msg);
    }
  }

  Future<UserEntity?> getMe() async {
    try {
      return await _datasource.getMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() => _datasource.logout();

  static final UserEntity _emptyUser = UserModel(
    id: '',
    username: '',
    fullName: '',
    isActive: false,
    roles: [],
  );
}
