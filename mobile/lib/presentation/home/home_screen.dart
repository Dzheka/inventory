import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентаризация'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Добро пожаловать!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user != null) ...[
              const SizedBox(height: 8),
              Text(user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(user.roles.join(', '),
                  style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Список активов'),
              onPressed: () => context.go('/home/assets'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сканер'),
              onPressed: () => context.go('/home/scanner'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Импорт данных'),
              onPressed: () => context.go('/home/import'),
            ),
          ],
        ),
      ),
    );
  }
}
