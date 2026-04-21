import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/asset_models.dart';
import '../../providers/asset_provider.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AssetModel> _filter(List<AssetModel> assets) {
    if (_query.isEmpty) return assets;
    final q = _query.toLowerCase();
    return assets
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.inventoryNumber.toLowerCase().contains(q) ||
            (a.barcode?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncAssets = ref.watch(assetListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентарь'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по названию или инв. номеру...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: asyncAssets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Ошибка загрузки', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(assetListProvider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (assets) {
          final filtered = _filter(assets);
          return RefreshIndicator(
            onRefresh: () => ref.read(assetListProvider.notifier).refresh(),
            child: filtered.isEmpty
                ? const Center(child: Text('Нет активов'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _AssetCard(asset: filtered[index]),
                  ),
          );
        },
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final AssetModel asset;

  const _AssetCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor(asset.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2_outlined,
                  color: _statusColor(asset.status)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Инв: ${asset.inventoryNumber}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusChip(
                          label: _statusLabel(asset.status),
                          color: _statusColor(asset.status)),
                      const SizedBox(width: 6),
                      _StatusChip(
                          label: _invStatusLabel(asset.inventoryStatus),
                          color: _invStatusColor(asset.inventoryStatus)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'active' => Colors.green,
        'written_off' => Colors.grey,
        'under_repair' => Colors.orange,
        'transferred' => Colors.blue,
        'missing' => Colors.red,
        _ => Colors.grey,
      };

  String _statusLabel(String s) => switch (s) {
        'active' => 'Активен',
        'written_off' => 'Списан',
        'under_repair' => 'Ремонт',
        'transferred' => 'Передан',
        'missing' => 'Утерян',
        _ => s,
      };

  Color _invStatusColor(String s) => switch (s) {
        'not_scanned' => Colors.grey,
        'found' => Colors.green,
        'not_found' => Colors.red,
        'surplus' => Colors.orange,
        'discrepancy' => Colors.orange,
        _ => Colors.grey,
      };

  String _invStatusLabel(String s) => switch (s) {
        'not_scanned' => 'Не сканирован',
        'found' => 'Найден',
        'not_found' => 'Не найден',
        'surplus' => 'Излишек',
        'discrepancy' => 'Расхождение',
        _ => s,
      };
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
