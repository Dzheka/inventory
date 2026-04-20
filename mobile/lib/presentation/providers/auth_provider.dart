import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserEntity? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    final user = await _repo.getMe();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _repo.login(username, password);
    if (result.error.isEmpty) {
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: result.error,
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
