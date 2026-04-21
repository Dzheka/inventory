import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/models/asset_models.dart';
import '../../../data/repositories/asset_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  AssetModel? _found;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() {
      _processing = true;
      _found = null;
      _error = null;
    });

    await _controller.stop();

    final asset =
        await ref.read(assetRepositoryProvider).getAssetByBarcode(barcode);

    if (!mounted) return;

    if (asset != null) {
      setState(() {
        _found = asset;
        _processing = false;
      });
    } else {
      setState(() {
        _error = 'Актив с баркодом "$barcode" не найден';
        _processing = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _found = null;
      _error = null;
      _processing = false;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // Scan frame overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_processing)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _found != null
                ? _AssetResult(asset: _found!, onRescan: _reset)
                : _error != null
                    ? _ErrorResult(message: _error!, onRescan: _reset)
                    : const _ScanHint(),
          ),
        ],
      ),
    );
  }
}

class _ScanHint extends StatelessWidget {
  const _ScanHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Наведите камеру на штрих-код',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorResult extends StatelessWidget {
  final String message;
  final VoidCallback onRescan;

  const _ErrorResult({required this.message, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Сканировать снова'),
            onPressed: onRescan,
          ),
        ],
      ),
    );
  }
}

class _AssetResult extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onRescan;

  const _AssetResult({required this.asset, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(asset.status);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Актив найден',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Ещё'),
                onPressed: onRescan,
              ),
            ],
          ),
          const Divider(),
          Text(asset.name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Инв. №: ${asset.inventoryNumber}',
              style: Theme.of(context).textTheme.bodySmall),
          if (asset.barcode != null)
            Text('Баркод: ${asset.barcode}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_statusLabel(asset.status),
                style: TextStyle(
                    color: statusColor, fontWeight: FontWeight.w500)),
          ),
        ],
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
}
