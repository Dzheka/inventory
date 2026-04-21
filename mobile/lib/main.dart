import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/router.dart';
import 'presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: InventoryApp()));
}

class InventoryApp extends ConsumerStatefulWidget {
  const InventoryApp({super.key});

  @override
  ConsumerState<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends ConsumerState<InventoryApp> {
  @override
  void initState() {
    super.initState();
    // Check persisted auth on startup
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).checkAuth(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
