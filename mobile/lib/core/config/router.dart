import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/pin_screen.dart';
import '../../presentation/assets/screens/asset_list_screen.dart';
import '../../presentation/assets/screens/file_import_screen.dart';
import '../../presentation/assets/screens/scanner_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/providers/auth_provider.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isInitial = authState.status == AuthStatus.initial;
      final onLoginPath = state.matchedLocation.startsWith('/login');

      if (isInitial) return null;
      if (!isAuth && !onLoginPath) return '/login';
      if (isAuth && onLoginPath) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'pin',
            builder: (_, __) => const PinScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'assets',
            builder: (_, __) => const AssetListScreen(),
          ),
          GoRoute(
            path: 'scanner',
            builder: (_, __) => const ScannerScreen(),
          ),
          GoRoute(
            path: 'import',
            builder: (_, __) => const FileImportScreen(),
          ),
        ],
      ),
    ],
  );
}
