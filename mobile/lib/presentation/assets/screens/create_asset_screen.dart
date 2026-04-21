import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/models/asset_models.dart';
import '../../providers/asset_provider.dart';

class CreateAssetScreen extends ConsumerStatefulWidget {
  const CreateAssetScreen({super.key});

  @override
  ConsumerState<CreateAssetScreen> createState() => _CreateAssetScreenState();
}

class _CreateAssetScreenState extends ConsumerState<CreateAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _invNumberController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _BarcodeScannerSheet(),
    );
    if (result != null && result.isNotEmpty) {
      _invNumberController.text = result;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final invNumber = _invNumberController.text.trim();
    await ref.read(createAssetProvider.notifier).create(
          CreateAssetRequest(
            inventoryNumber: invNumber,
            name: _nameController.text.trim(),
            barcode: invNumber,
            description: _descriptionController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createAssetProvider, (_, state) {
      if (state.status == CreateStatus.success) {
        ref.read(assetListProvider.notifier).refresh();
        ref.read(createAssetProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Актив создан'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    });

    final state = ref.watch(createAssetProvider);
    final isLoading = state.status == CreateStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Новый актив')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _invNumberController,
                decoration: InputDecoration(
                  labelText: 'Инвентарный номер *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Сканировать',
                    onPressed: _scanBarcode,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (state.status == CreateStatus.error) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.error ?? 'Ошибка',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Создать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null) return;
    _detected = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                const Text('Сканировать штрих-код',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _controller.toggleTorch(),
                ),
                const SizedBox(width: 8),
                const Text('Наведите камеру на штрих-код',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
